#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# 🦞 OpenClaw Auto Setup for Termux (Android)
# One-liner: curl -fsSL https://raw.githubusercontent.com/<YOUR_GITHUB>/openclaw-termux-setup/main/setup.sh | bash
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
LOBSTER='🦞'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ${LOBSTER} OpenClaw Termux Auto Setup ${LOBSTER}         ║${NC}"
echo -e "${CYAN}║  Personal AI Assistant on Android        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ---- Step 1: Update & upgrade Termux packages ----
echo -e "${GREEN}[1/7]${NC} Updating Termux packages..."
pkg update -y && pkg upgrade -y

# ---- Step 2: Install required packages ----
echo -e "${GREEN}[2/7]${NC} Installing Node.js, Git, tmux, and tools..."
pkg install -y nodejs-lts git tmux cronie termux-api

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
echo -e "${GREEN}[3/7]${NC} Installing OpenClaw..."
npm install -g openclaw@latest

# Verify
OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "FAILED")
echo -e "  ${CYAN}OpenClaw:${NC} $OPENCLAW_VERSION"

if [ "$OPENCLAW_VERSION" = "FAILED" ]; then
  echo -e "${RED}❌ OpenClaw installation failed.${NC}"
  exit 1
fi

# ---- Step 4: Setup wake-lock to prevent Android from killing Termux ----
echo -e "${GREEN}[4/7]${NC} Setting up wake-lock (prevent Android sleep kill)..."
termux-wake-lock 2>/dev/null || echo "  (termux-wake-lock not available, skipping)"

# ---- Step 5: Create auto-start script for Termux:Boot ----
echo -e "${GREEN}[5/7]${NC} Setting up auto-start on boot..."
mkdir -p ~/.termux/boot

cat > ~/.termux/boot/start-openclaw.sh << 'BOOTEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Auto-start OpenClaw on boot
termux-wake-lock 2>/dev/null
sleep 5
# Start gateway in tmux session
if ! tmux has-session -t openclaw 2>/dev/null; then
  tmux new-session -d -s openclaw 'openclaw gateway --port 18789 --verbose'
fi
BOOTEOF
chmod +x ~/.termux/boot/start-openclaw.sh

# ---- Step 6: Create helper scripts ----
echo -e "${GREEN}[6/7]${NC} Creating helper scripts..."

# Start script
cat > ~/openclaw-start.sh << 'STARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🦞 Starting OpenClaw Gateway..."
termux-wake-lock 2>/dev/null
if tmux has-session -t openclaw 2>/dev/null; then
  echo "OpenClaw is already running! Use: tmux attach -t openclaw"
else
  tmux new-session -d -s openclaw 'openclaw gateway --port 18789 --verbose'
  echo "✅ OpenClaw started in tmux session 'openclaw'"
  echo ""
  # Get IP address
  IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
  if [ -n "$IP" ]; then
    echo "📱 Access Web UI from your browser:"
    echo "   http://${IP}:18789"
  fi
  echo ""
  echo "Commands:"
  echo "  tmux attach -t openclaw   → View logs"
  echo "  Ctrl+B then D             → Detach (keep running)"
  echo "  ~/openclaw-stop.sh        → Stop OpenClaw"
fi
STARTEOF
chmod +x ~/openclaw-start.sh

# Stop script
cat > ~/openclaw-stop.sh << 'STOPEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🦞 Stopping OpenClaw..."
tmux kill-session -t openclaw 2>/dev/null && echo "✅ Stopped" || echo "⚠️ Not running"
termux-wake-unlock 2>/dev/null
STOPEOF
chmod +x ~/openclaw-stop.sh

# Status script
cat > ~/openclaw-status.sh << 'STATUSEOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "🦞 OpenClaw Status"
echo "===================="
if tmux has-session -t openclaw 2>/dev/null; then
  echo "✅ Gateway: RUNNING"
else
  echo "❌ Gateway: STOPPED"
fi
IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
echo "📍 IP: ${IP:-unknown}"
echo "🌐 Web UI: http://${IP:-<IP>}:18789"
echo ""
echo "Commands:"
echo "  ~/openclaw-start.sh    → Start"
echo "  ~/openclaw-stop.sh     → Stop"
echo "  tmux attach -t openclaw → View logs"
STATUSEOF
chmod +x ~/openclaw-status.sh

# ---- Step 7: Create default config (bind to 0.0.0.0 for LAN access) ----
echo -e "${GREEN}[7/7]${NC} Creating default config..."
mkdir -p ~/.openclaw

# Only create config if it doesn't exist
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
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ${LOBSTER} Setup Complete!                       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo ""
echo -e "  ${YELLOW}1. Run onboard (first time setup):${NC}"
echo "     openclaw onboard"
echo ""
echo -e "  ${YELLOW}2. Or manually add API key:${NC}"
echo "     Edit ~/.openclaw/openclaw.json"
echo "     Add your Anthropic/OpenAI API key"
echo ""
echo -e "  ${YELLOW}3. Start OpenClaw:${NC}"
echo "     ~/openclaw-start.sh"
echo ""
echo -e "  ${YELLOW}4. Access Web UI:${NC}"
IP=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
echo "     http://${IP:-<your-phone-ip>}:18789"
echo ""
echo -e "${CYAN}Helper commands:${NC}"
echo "  ~/openclaw-start.sh     → Start gateway"
echo "  ~/openclaw-stop.sh      → Stop gateway"
echo "  ~/openclaw-status.sh    → Check status & IP"
echo "  tmux attach -t openclaw → View live logs"
echo ""
echo -e "${CYAN}Tips for K40 Pro / MIUI:${NC}"
echo "  • Lock Termux in Recent Apps (swipe down on lock icon)"
echo "  • Settings → Apps → Termux → Battery → No restrictions"
echo "  • Settings → WiFi → Advanced → Keep WiFi on during sleep"
echo "  • Install 'Termux:Boot' from F-Droid for auto-start"
echo ""
echo -e "${GREEN}Happy clawing! ${LOBSTER}${NC}"
