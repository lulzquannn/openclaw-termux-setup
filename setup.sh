#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# 🦞 OpenClaw Auto Setup for Termux (Android)
# One-liner: curl -fsSL https://raw.githubusercontent.com/lulzquannn/openclaw-termux-setup/master/setup.sh | bash
# Includes: Cloudflare Tunnel for public access (no port forwarding needed)
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
LOBSTER='🦞'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${LOBSTER} OpenClaw Termux Auto Setup ${LOBSTER}             ║${NC}"
echo -e "${CYAN}║  Personal AI Assistant on Android            ║${NC}"
echo -e "${CYAN}║  + Cloudflare Tunnel (public access)         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ---- Step 1: Update & upgrade Termux packages ----
echo -e "${GREEN}[1/8]${NC} Updating Termux packages..."
pkg update -y && pkg upgrade -y

# ---- Step 2: Install required packages ----
echo -e "${GREEN}[2/8]${NC} Installing Node.js, Git, tmux, and tools..."
pkg install -y nodejs-lts git tmux cronie termux-api wget

# Verify Node.js
NODE_VERSION=$(node -v 2>/dev/null || echo "FAILED")
NPM_VERSION=$(npm -v 2>/dev/null || echo "FAILED")
echo -e "  ${CYAN}Node.js:${NC} $NODE_VERSION"
echo -e "  ${CYAN}npm:${NC}    $NPM_VERSION"

if [ "$NODE_VERSION" = "FAILED" ]; then
  echo -e "${RED}❌ Node.js installation failed. Please try manually: pkg install nodejs-lts${NC}"
  exit 1
fi

# ---- Step 3: Install OpenClaw globally ----
echo -e "${GREEN}[3/8]${NC} Installing OpenClaw..."
npm install -g openclaw@latest

# Verify
OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "FAILED")
echo -e "  ${CYAN}OpenClaw:${NC} $OPENCLAW_VERSION"

if [ "$OPENCLAW_VERSION" = "FAILED" ]; then
  echo -e "${RED}❌ OpenClaw installation failed.${NC}"
  exit 1
fi

# ---- Step 4: Install Cloudflare Tunnel (cloudflared) ----
echo -e "${GREEN}[4/8]${NC} Installing Cloudflare Tunnel (cloudflared)..."

ARCH=$(uname -m)
CF_INSTALLED=false

if command -v cloudflared &>/dev/null; then
  echo -e "  ${CYAN}cloudflared already installed${NC}"
  CF_INSTALLED=true
else
  # Detect architecture and download appropriate binary
  case "$ARCH" in
    aarch64|arm64)
      CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
      ;;
    armv7l|armv8l)
      CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
      ;;
    x86_64)
      CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
      ;;
    *)
      echo -e "  ${YELLOW}⚠️ Unknown architecture: $ARCH. Skipping cloudflared.${NC}"
      CF_URL=""
      ;;
  esac

  if [ -n "$CF_URL" ]; then
    echo -e "  ${CYAN}Downloading cloudflared for $ARCH...${NC}"
    wget -q -O $PREFIX/bin/cloudflared "$CF_URL" 2>/dev/null || curl -sL -o $PREFIX/bin/cloudflared "$CF_URL"
    chmod +x $PREFIX/bin/cloudflared
    if command -v cloudflared &>/dev/null; then
      echo -e "  ${GREEN}✅ cloudflared installed${NC}"
      CF_INSTALLED=true
    else
      echo -e "  ${YELLOW}⚠️ cloudflared install failed, tunnel won't be available${NC}"
    fi
  fi
fi

# ---- Step 5: Setup wake-lock ----
echo -e "${GREEN}[5/8]${NC} Setting up wake-lock (prevent Android sleep kill)..."
termux-wake-lock 2>/dev/null || echo "  (termux-wake-lock not available, skipping)"

# ---- Step 6: Create auto-start script for Termux:Boot ----
echo -e "${GREEN}[6/8]${NC} Setting up auto-start on boot..."
mkdir -p ~/.termux/boot

cat > ~/.termux/boot/start-openclaw.sh << 'BOOTEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Auto-start OpenClaw + Cloudflare Tunnel on boot
termux-wake-lock 2>/dev/null
sleep 5

# Start gateway in tmux session
if ! tmux has-session -t openclaw 2>/dev/null; then
  tmux new-session -d -s openclaw 'openclaw gateway --port 18789 --verbose'
fi

# Start cloudflare tunnel in tmux session
sleep 3
if command -v cloudflared &>/dev/null; then
  if ! tmux has-session -t tunnel 2>/dev/null; then
    tmux new-session -d -s tunnel 'cloudflared tunnel --url http://localhost:18789 2>&1 | tee ~/tunnel.log'
  fi
fi
BOOTEOF
chmod +x ~/.termux/boot/start-openclaw.sh

# ---- Step 7: Create helper scripts ----
echo -e "${GREEN}[7/8]${NC} Creating helper scripts..."

# Start script (OpenClaw + Tunnel)
cat > ~/openclaw-start.sh << 'STARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🦞 Starting OpenClaw Gateway + Tunnel..."
termux-wake-lock 2>/dev/null

# Start OpenClaw Gateway
if tmux has-session -t openclaw 2>/dev/null; then
  echo "✅ OpenClaw Gateway already running"
else
  tmux new-session -d -s openclaw 'openclaw gateway --port 18789 --verbose'
  echo "✅ OpenClaw Gateway started"
fi

# Wait for gateway to be ready
sleep 3

# Start Cloudflare Tunnel
if command -v cloudflared &>/dev/null; then
  if tmux has-session -t tunnel 2>/dev/null; then
    echo "✅ Cloudflare Tunnel already running"
  else
    # Start tunnel and capture URL
    tmux new-session -d -s tunnel 'cloudflared tunnel --url http://localhost:18789 2>&1 | tee ~/tunnel.log'
    echo "⏳ Starting Cloudflare Tunnel..."
    sleep 5

    # Extract the public URL from tunnel log
    TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' ~/tunnel.log 2>/dev/null | head -1)
    if [ -n "$TUNNEL_URL" ]; then
      echo "$TUNNEL_URL" > ~/tunnel-url.txt
      echo ""
      echo "╔══════════════════════════════════════════════╗"
      echo "║  🌐 PUBLIC URL (access from anywhere):       ║"
      echo "║  $TUNNEL_URL"
      echo "╚══════════════════════════════════════════════╝"
      echo ""
    else
      echo "  ⏳ Tunnel still starting... check in a few seconds:"
      echo "  ~/openclaw-url.sh"
    fi
  fi
else
  echo "⚠️ cloudflared not installed. LAN access only."
fi

# Show LAN access
IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
echo ""
echo "📱 LAN access: http://${IP:-<phone-ip>}:18789"
echo ""
echo "Commands:"
echo "  ~/openclaw-url.sh         → Show public URL"
echo "  ~/openclaw-status.sh      → Full status"
echo "  ~/openclaw-stop.sh        → Stop everything"
echo "  tmux attach -t openclaw   → View gateway logs"
echo "  tmux attach -t tunnel     → View tunnel logs"
STARTEOF
chmod +x ~/openclaw-start.sh

# URL script - get the public URL
cat > ~/openclaw-url.sh << 'URLEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🦞 OpenClaw Public URL"
echo "======================"

# Try to get URL from saved file first
if [ -f ~/tunnel-url.txt ]; then
  SAVED_URL=$(cat ~/tunnel-url.txt)
  echo "🌐 Last known URL: $SAVED_URL"
fi

# Try to get fresh URL from tunnel log
if [ -f ~/tunnel.log ]; then
  TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' ~/tunnel.log 2>/dev/null | tail -1)
  if [ -n "$TUNNEL_URL" ]; then
    echo "$TUNNEL_URL" > ~/tunnel-url.txt
    echo "🌐 Current URL:    $TUNNEL_URL"
    echo ""
    echo "📋 Copy this URL and open in any browser!"
    echo "   No WiFi/VPN needed - works from anywhere."
  else
    echo "⏳ Tunnel URL not available yet. Wait a moment and try again."
    echo "   Or check: tmux attach -t tunnel"
  fi
else
  echo "❌ Tunnel not running. Start with: ~/openclaw-start.sh"
fi

echo ""
IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
echo "📱 LAN access: http://${IP:-<phone-ip>}:18789"
URLEOF
chmod +x ~/openclaw-url.sh

# Stop script
cat > ~/openclaw-stop.sh << 'STOPEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🦞 Stopping OpenClaw..."
tmux kill-session -t openclaw 2>/dev/null && echo "✅ Gateway stopped" || echo "⚠️ Gateway not running"
tmux kill-session -t tunnel 2>/dev/null && echo "✅ Tunnel stopped" || echo "⚠️ Tunnel not running"
rm -f ~/tunnel.log ~/tunnel-url.txt
termux-wake-unlock 2>/dev/null
echo "Done!"
STOPEOF
chmod +x ~/openclaw-stop.sh

# Status script
cat > ~/openclaw-status.sh << 'STATUSEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🦞 OpenClaw Status"
echo "=========================="

# Gateway status
if tmux has-session -t openclaw 2>/dev/null; then
  echo "✅ Gateway:  RUNNING"
else
  echo "❌ Gateway:  STOPPED"
fi

# Tunnel status
if tmux has-session -t tunnel 2>/dev/null; then
  echo "✅ Tunnel:   RUNNING"
  TUNNEL_URL=$(grep -o 'https://[a-z0-9-]*\.trycloudflare\.com' ~/tunnel.log 2>/dev/null | tail -1)
  if [ -n "$TUNNEL_URL" ]; then
    echo "🌐 Public:   $TUNNEL_URL"
  fi
else
  echo "❌ Tunnel:   STOPPED"
fi

# LAN info
IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
echo "📍 LAN IP:   ${IP:-unknown}"
echo "📱 LAN URL:  http://${IP:-<IP>}:18789"
echo ""
echo "Commands:"
echo "  ~/openclaw-start.sh    → Start all"
echo "  ~/openclaw-stop.sh     → Stop all"
echo "  ~/openclaw-url.sh      → Show public URL"
echo "  tmux attach -t openclaw → Gateway logs"
echo "  tmux attach -t tunnel   → Tunnel logs"
STATUSEOF
chmod +x ~/openclaw-status.sh

# Restart script
cat > ~/openclaw-restart.sh << 'RESTARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🦞 Restarting OpenClaw..."
~/openclaw-stop.sh
sleep 2
~/openclaw-start.sh
RESTARTEOF
chmod +x ~/openclaw-restart.sh

# ---- Step 8: Create default config ----
echo -e "${GREEN}[8/8]${NC} Creating default config..."
mkdir -p ~/.openclaw

if [ ! -f ~/.openclaw/openclaw.json ]; then
  cat > ~/.openclaw/openclaw.json << 'CONFIGEOF'
{
  "gateway": {
    "bind": "0.0.0.0",
    "port": 18789
  },
  "agent": {
    "model": "anthropic/claude-3-5-haiku-latest"
  }
}
CONFIGEOF
  echo -e "  ${CYAN}Config created at:${NC} ~/.openclaw/openclaw.json"
  echo -e "  ${YELLOW}⚠️  You still need to add your API key!${NC}"
else
  echo -e "  ${CYAN}Config already exists, skipping.${NC}"
fi

# ---- Done! ----
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ${LOBSTER} Setup Complete!                             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo ""
echo -e "  ${YELLOW}1. Run onboard (first time setup):${NC}"
echo "     openclaw onboard"
echo ""
echo -e "  ${YELLOW}2. Start OpenClaw + Public Tunnel:${NC}"
echo "     ~/openclaw-start.sh"
echo ""
echo -e "  ${YELLOW}3. Get your public URL:${NC}"
echo "     ~/openclaw-url.sh"
echo ""
echo -e "  ${YELLOW}4. Access from ANYWHERE:${NC}"
echo "     Open the https://xxxxx.trycloudflare.com URL in any browser"
echo "     No VPN, no port forwarding, no same WiFi needed!"
echo ""
echo -e "${CYAN}All commands:${NC}"
echo "  ~/openclaw-start.sh     → Start gateway + tunnel"
echo "  ~/openclaw-stop.sh      → Stop everything"
echo "  ~/openclaw-restart.sh   → Restart everything"
echo "  ~/openclaw-status.sh    → Check status"
echo "  ~/openclaw-url.sh       → Get public URL"
echo "  tmux attach -t openclaw → View gateway logs"
echo "  tmux attach -t tunnel   → View tunnel logs"
echo ""
echo -e "${CYAN}Tips for K40 Pro / MIUI:${NC}"
echo "  • Lock Termux in Recent Apps (swipe down on lock icon)"
echo "  • Settings → Apps → Termux → Battery → No restrictions"
echo "  • Settings → WiFi → Advanced → Keep WiFi on during sleep"
echo "  • Install 'Termux:Boot' from F-Droid for auto-start"
echo ""
echo -e "${YELLOW}Note: Cloudflare Tunnel URL changes on each restart.${NC}"
echo -e "${YELLOW}Run ~/openclaw-url.sh to get the current URL.${NC}"
echo ""
echo -e "${GREEN}Happy clawing! ${LOBSTER}${NC}"
