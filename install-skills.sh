#!/usr/bin/env bash
# ============================================
# 🦞 OpenClaw Skills Installer
# Install popular skills from ClawHub
# Run after: openclaw onboard + ~/openclaw-start.sh
# ============================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🦞 OpenClaw Skills Installer                ║${NC}"
echo -e "${CYAN}║  Install popular skills from ClawHub          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Check if OpenClaw is installed
if ! command -v openclaw &>/dev/null; then
  echo -e "${RED}❌ OpenClaw not installed. Run setup.sh first.${NC}"
  exit 1
fi

echo -e "${CYAN}Available skill packs:${NC}"
echo ""
echo "  1) 🌟 Essential Pack (recommended)"
echo "     weather, summarize, coding-agent, gh-issues, skill-creator"
echo ""
echo "  2) 📱 Social & Communication"
echo "     discord, slack, trello"
echo ""
echo "  3) 🤖 AI & Automation"
echo "     gemini, coding-agent, blogwatcher"
echo ""
echo "  4) 🎯 All Popular Skills"
echo "     Everything above + more"
echo ""
echo "  5) 📋 Custom (enter skill names)"
echo ""
echo "  6) 🔍 Browse ClawHub (opens https://clawhub.com)"
echo ""

read -p "Choose option (1-6): " CHOICE

install_skill() {
  local skill=$1
  echo -e "  ${CYAN}Installing:${NC} $skill..."
  openclaw skills install "$skill" 2>/dev/null && \
    echo -e "  ${GREEN}✅ $skill installed${NC}" || \
    echo -e "  ${YELLOW}⚠️ $skill failed (may already exist or not found)${NC}"
}

case "$CHOICE" in
  1)
    echo -e "\n${GREEN}Installing Essential Pack...${NC}\n"
    for skill in weather summarize coding-agent gh-issues skill-creator; do
      install_skill "$skill"
    done
    ;;
  2)
    echo -e "\n${GREEN}Installing Social & Communication Pack...${NC}\n"
    for skill in discord slack trello; do
      install_skill "$skill"
    done
    ;;
  3)
    echo -e "\n${GREEN}Installing AI & Automation Pack...${NC}\n"
    for skill in gemini coding-agent blogwatcher; do
      install_skill "$skill"
    done
    ;;
  4)
    echo -e "\n${GREEN}Installing All Popular Skills...${NC}\n"
    for skill in weather summarize coding-agent gh-issues skill-creator discord slack trello gemini blogwatcher xurl gifgrep session-logs tmux; do
      install_skill "$skill"
    done
    ;;
  5)
    echo ""
    echo "Enter skill names separated by space:"
    echo "(Browse https://clawhub.com for available skills)"
    read -p "> " CUSTOM_SKILLS
    echo ""
    for skill in $CUSTOM_SKILLS; do
      install_skill "$skill"
    done
    ;;
  6)
    echo ""
    echo "Opening ClawHub..."
    echo "Browse skills at: https://clawhub.com"
    echo ""
    echo "To install a skill manually:"
    echo "  openclaw skills install <skill-name>"
    echo ""
    echo "To list installed skills:"
    echo "  openclaw skills list"
    ;;
  *)
    echo -e "${RED}Invalid option${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}Done! 🦞${NC}"
echo ""
echo "Useful commands:"
echo "  openclaw skills list              → List installed skills"
echo "  openclaw skills install <name>    → Install a skill"
echo "  openclaw skills update --all      → Update all skills"
echo "  Browse more: https://clawhub.com"
