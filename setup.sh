#!/usr/bin/env bash
# ============================================
# 🦞 OpenClaw Auto Setup for Termux (Android) & Linux
# One-liner: curl -fsSL https://raw.githubusercontent.com/lulzquannn/openclaw-termux-setup/master/setup.sh | bash
# Includes: Cloudflare Tunnel for public access (no port forwarding needed)
# Works on: Termux (Android), Ubuntu/Debian, Arch, macOS
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
LOBSTER='🦞'

# Detect environment
IS_TERMUX=false
if [ -d "/data/data/com.termux" ]; then
  IS_TERMUX=true
fi

# Detect package manager
detect_pkg_manager() {
  if $IS_TERMUX && command -v pkg &>/dev/null; then
    echo "termux"
  elif command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v dnf &>/dev/null; then
    echo "dnf"
  elif command -v yum &>/dev/null; then
    echo "yum"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  elif command -v brew &>/dev/null; then
    echo "brew"
  elif command -v apk &>/dev/null; then
    echo "apk"
  else
    echo "unknown"
  fi
}

PKG_MANAGER=$(detect_pkg_manager)

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${LOBSTER} OpenClaw Auto Setup ${LOBSTER}                     ║${NC}"
echo -e "${CYAN}║  Personal AI Assistant                       ║${NC}"
echo -e "${CYAN}║  + Cloudflare Tunnel (public access)         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""
if $IS_TERMUX; then
  echo -e "${CYAN}Environment: Termux (Android)${NC}"
else
  echo -e "${CYAN}Environment: Linux/macOS (pkg manager: $PKG_MANAGER)${NC}"
fi
echo ""

# ---- Step 1: Update packages ----
echo -e "${GREEN}[1/8]${NC} Updating system packages..."
case "$PKG_MANAGER" in
  termux)
    pkg update -y && pkg upgrade -y
    ;;
  apt)
    sudo apt-get update -y && sudo apt-get upgrade -y
    ;;
  dnf|yum)
    sudo $PKG_MANAGER update -y
    ;;
  pacman)
    sudo pacman -Syu --noconfirm
    ;;
  brew)
    brew update
    ;;
  apk)
    sudo apk update && sudo apk upgrade
    ;;
  *)
    echo -e "  ${YELLOW}⚠️ Unknown package manager. Skipping system update.${NC}"
    ;;
esac

# ---- Step 2: Install required packages ----
echo -e "${GREEN}[2/8]${NC} Installing Node.js, Git, tmux, and tools..."

install_nodejs() {
  if command -v node &>/dev/null; then
    echo -e "  ${CYAN}Node.js already installed${NC}"
    return
  fi

  case "$PKG_MANAGER" in
    termux)
      pkg install -y nodejs-lts git tmux cronie termux-api wget
      ;;
    apt)
      # Install Node.js via NodeSource if not available
      if ! command -v node &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - 2>/dev/null || true
        sudo apt-get install -y nodejs git tmux wget curl
      fi
      ;;
    dnf|yum)
      curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - 2>/dev/null || true
      sudo $PKG_MANAGER install -y nodejs git tmux wget curl
      ;;
    pacman)
      sudo pacman -S --noconfirm nodejs npm git tmux wget curl
      ;;
    brew)
      brew install node git tmux wget curl
      ;;
    apk)
      sudo apk add nodejs npm git tmux wget curl
      ;;
    *)
      echo -e "  ${YELLOW}⚠️ Please install Node.js manually: https://nodejs.org${NC}"
      ;;
  esac
}

install_nodejs

# Verify Node.js
NODE_VERSION=$(node -v 2>/dev/null || echo "FAILED")
NPM_VERSION=$(npm -v 2>/dev/null || echo "FAILED")
echo -e "  ${CYAN}Node.js:${NC} $NODE_VERSION"
echo -e "  ${CYAN}npm:${NC}    $NPM_VERSION"

if [ "$NODE_VERSION" = "FAILED" ]; then
  echo -e "${RED}❌ Node.js installation failed.${NC}"
  echo -e "${RED}   Please install Node.js 22+ manually: https://nodejs.org${NC}"
  exit 1
fi

# ---- Step 3: Install OpenClaw globally ----
echo -e "${GREEN}[3/8]${NC} Installing OpenClaw..."
npm install -g openclaw@latest 2>/dev/null || sudo npm install -g openclaw@latest

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
  # Try package manager first
  case "$PKG_MANAGER" in
    apt)
      # Try installing via apt
      curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null 2>&1
      echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null 2>&1
      sudo apt-get update -y 2>/dev/null && sudo apt-get install -y cloudflared 2>/dev/null && CF_INSTALLED=true
      ;;
    brew)
      brew install cloudflared 2>/dev/null && CF_INSTALLED=true
      ;;
  esac

  # Fallback: download binary directly
  if ! $CF_INSTALLED; then
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
      BIN_DIR="${PREFIX:-/usr/local}/bin"
      if $IS_TERMUX; then
        BIN_DIR="$PREFIX/bin"
      fi
      wget -q -O "$BIN_DIR/cloudflared" "$CF_URL" 2>/dev/null || \
        curl -sL -o "$BIN_DIR/cloudflared" "$CF_URL" 2>/dev/null || \
        sudo wget -q -O /usr/local/bin/cloudflared "$CF_URL" 2>/dev/null || \
        sudo curl -sL -o /usr/local/bin/cloudflared "$CF_URL"
      chmod +x "$BIN_DIR/cloudflared" 2>/dev/null || sudo chmod +x /usr/local/bin/cloudflared
      if command -v cloudflared &>/dev/null; then
        echo -e "  ${GREEN}✅ cloudflared installed${NC}"
        CF_INSTALLED=true
      else
        echo -e "  ${YELLOW}⚠️ cloudflared install failed, tunnel won't be available${NC}"
      fi
    fi
  fi
fi

# ---- Step 5: Setup wake-lock (Termux only) ----
echo -e "${GREEN}[5/8]${NC} Setting up wake-lock..."
if $IS_TERMUX; then
  termux-wake-lock 2>/dev/null || echo "  (termux-wake-lock not available, skipping)"
else
  echo "  (Not Termux, skipping wake-lock)"
fi

# ---- Step 6: Create auto-start script ----
echo -e "${GREEN}[6/8]${NC} Setting up auto-start..."
if $IS_TERMUX; then
  mkdir -p ~/.termux/boot
  cat > ~/.termux/boot/start-openclaw.sh << 'BOOTEOF'
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock 2>/dev/null
sleep 5
if ! tmux has-session -t openclaw 2>/dev/null; then
  tmux new-session -d -s openclaw 'openclaw gateway --port 18789 --verbose'
fi
sleep 3
if command -v cloudflared &>/dev/null; then
  if ! tmux has-session -t tunnel 2>/dev/null; then
    tmux new-session -d -s tunnel 'cloudflared tunnel --url http://localhost:18789 2>&1 | tee ~/tunnel.log'
  fi
fi
BOOTEOF
  chmod +x ~/.termux/boot/start-openclaw.sh
  echo "  Auto-start script created for Termux:Boot"
else
  echo "  (Not Termux — use systemd or crontab for auto-start on Linux)"
fi

# ---- Step 7: Create helper scripts ----
echo -e "${GREEN}[7/8]${NC} Creating helper scripts..."

# Start script (OpenClaw + Tunnel)
cat > ~/openclaw-start.sh << 'STARTEOF'
#!/usr/bin/env bash
echo "🦞 Starting OpenClaw Gateway + Tunnel..."

# Wake-lock for Termux
if [ -d "/data/data/com.termux" ]; then
  termux-wake-lock 2>/dev/null
fi

# Start OpenClaw Gateway
if command -v tmux &>/dev/null; then
  if tmux has-session -t openclaw 2>/dev/null; then
    echo "✅ OpenClaw Gateway already running"
  else
    tmux new-session -d -s openclaw 'openclaw gateway --port 18789 --verbose'
    echo "✅ OpenClaw Gateway started"
  fi
else
  echo "Starting OpenClaw Gateway (foreground - install tmux for background)..."
  openclaw gateway --port 18789 --verbose &
  echo "✅ OpenClaw Gateway started (PID: $!)"
fi

# Wait for gateway to be ready
sleep 3

# Start Cloudflare Tunnel
if command -v cloudflared &>/dev/null; then
  if command -v tmux &>/dev/null && tmux has-session -t tunnel 2>/dev/null; then
    echo "✅ Cloudflare Tunnel already running"
  else
    if command -v tmux &>/dev/null; then
      tmux new-session -d -s tunnel 'cloudflared tunnel --url http://localhost:18789 2>&1 | tee ~/tunnel.log'
    else
      cloudflared tunnel --url http://localhost:18789 > ~/tunnel.log 2>&1 &
    fi
    echo "⏳ Starting Cloudflare Tunnel..."
    sleep 6

    # Extract the public URL
    TUNNEL_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' ~/tunnel.log 2>/dev/null | head -1)
    if [ -n "$TUNNEL_URL" ]; then
      echo "$TUNNEL_URL" > ~/tunnel-url.txt
      echo ""
      echo "╔══════════════════════════════════════════════════╗"
      echo "║  🌐 PUBLIC URL (access from anywhere):           ║"
      echo "║  $TUNNEL_URL"
      echo "╚══════════════════════════════════════════════════╝"
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
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
echo ""
echo "📱 LAN access: http://${IP:-localhost}:18789"
echo ""
echo "Commands:"
echo "  ~/openclaw-url.sh         → Show public URL"
echo "  ~/openclaw-status.sh      → Full status"
echo "  ~/openclaw-stop.sh        → Stop everything"
if command -v tmux &>/dev/null; then
  echo "  tmux attach -t openclaw   → View gateway logs"
  echo "  tmux attach -t tunnel     → View tunnel logs"
fi
STARTEOF
chmod +x ~/openclaw-start.sh

# URL script
cat > ~/openclaw-url.sh << 'URLEOF'
#!/usr/bin/env bash
echo "🦞 OpenClaw Public URL"
echo "======================"

if [ -f ~/tunnel.log ]; then
  TUNNEL_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' ~/tunnel.log 2>/dev/null | tail -1)
  if [ -n "$TUNNEL_URL" ]; then
    echo "$TUNNEL_URL" > ~/tunnel-url.txt
    echo "🌐 Public URL: $TUNNEL_URL"
    echo ""
    echo "📋 Open this URL in any browser — works from anywhere!"
  else
    echo "⏳ Tunnel URL not available yet. Wait and try again."
  fi
elif [ -f ~/tunnel-url.txt ]; then
  echo "🌐 Last known URL: $(cat ~/tunnel-url.txt)"
else
  echo "❌ Tunnel not running. Start with: ~/openclaw-start.sh"
fi

echo ""
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
echo "📱 LAN access: http://${IP:-localhost}:18789"
URLEOF
chmod +x ~/openclaw-url.sh

# Stop script
cat > ~/openclaw-stop.sh << 'STOPEOF'
#!/usr/bin/env bash
echo "🦞 Stopping OpenClaw..."
if command -v tmux &>/dev/null; then
  tmux kill-session -t openclaw 2>/dev/null && echo "✅ Gateway stopped" || echo "⚠️ Gateway not running"
  tmux kill-session -t tunnel 2>/dev/null && echo "✅ Tunnel stopped" || echo "⚠️ Tunnel not running"
else
  pkill -f "openclaw gateway" 2>/dev/null && echo "✅ Gateway stopped" || echo "⚠️ Gateway not running"
  pkill -f "cloudflared tunnel" 2>/dev/null && echo "✅ Tunnel stopped" || echo "⚠️ Tunnel not running"
fi
rm -f ~/tunnel.log ~/tunnel-url.txt
if [ -d "/data/data/com.termux" ]; then
  termux-wake-unlock 2>/dev/null
fi
echo "Done!"
STOPEOF
chmod +x ~/openclaw-stop.sh

# Status script
cat > ~/openclaw-status.sh << 'STATUSEOF'
#!/usr/bin/env bash
echo "🦞 OpenClaw Status"
echo "=========================="

if command -v tmux &>/dev/null; then
  if tmux has-session -t openclaw 2>/dev/null; then
    echo "✅ Gateway:  RUNNING"
  else
    echo "❌ Gateway:  STOPPED"
  fi
  if tmux has-session -t tunnel 2>/dev/null; then
    echo "✅ Tunnel:   RUNNING"
  else
    echo "❌ Tunnel:   STOPPED"
  fi
else
  pgrep -f "openclaw gateway" >/dev/null 2>&1 && echo "✅ Gateway:  RUNNING" || echo "❌ Gateway:  STOPPED"
  pgrep -f "cloudflared tunnel" >/dev/null 2>&1 && echo "✅ Tunnel:   RUNNING" || echo "❌ Tunnel:   STOPPED"
fi

TUNNEL_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' ~/tunnel.log 2>/dev/null | tail -1)
if [ -n "$TUNNEL_URL" ]; then
  echo "🌐 Public:   $TUNNEL_URL"
fi

IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
echo "📍 LAN IP:   ${IP:-unknown}"
echo "📱 LAN URL:  http://${IP:-localhost}:18789"
echo ""
echo "Commands:"
echo "  ~/openclaw-start.sh    → Start all"
echo "  ~/openclaw-stop.sh     → Stop all"
echo "  ~/openclaw-url.sh      → Show public URL"
STATUSEOF
chmod +x ~/openclaw-status.sh

# Restart script
cat > ~/openclaw-restart.sh << 'RESTARTEOF'
#!/usr/bin/env bash
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
if $IS_TERMUX; then
  echo -e "${CYAN}Platform: Termux (Android)${NC}"
else
  echo -e "${CYAN}Platform: Linux/macOS${NC}"
fi
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
echo ""
if $IS_TERMUX; then
  echo -e "${CYAN}Tips for Android / MIUI:${NC}"
  echo "  • Lock Termux in Recent Apps (swipe down on lock icon)"
  echo "  • Settings → Apps → Termux → Battery → No restrictions"
  echo "  • Settings → WiFi → Advanced → Keep WiFi on during sleep"
  echo "  • Install 'Termux:Boot' from F-Droid for auto-start"
  echo ""
fi
echo -e "${YELLOW}Note: Cloudflare Tunnel URL changes on each restart.${NC}"
echo -e "${YELLOW}Run ~/openclaw-url.sh to get the current URL.${NC}"
echo ""
echo -e "${GREEN}Happy clawing! ${LOBSTER}${NC}"
