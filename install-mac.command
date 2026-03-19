#!/usr/bin/env bash
set -e

# ─── Stixor CRM MCP Server — Mac Installer ───
# Double-click this file to install.

# Load shell profile so Homebrew/nvm/fnm paths are available
# (double-clicking .command files runs in a minimal shell)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc" 2>/dev/null || true
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true
[ -f "$HOME/.nvm/nvm.sh" ] && source "$HOME/.nvm/nvm.sh" 2>/dev/null || true

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

cd "$(dirname "$0")"

echo ""
echo -e "${BOLD}════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Stixor CRM MCP Server — Installer${NC}"
echo -e "${BOLD}════════════════════════════════════════════${NC}"
echo ""

# Check Node.js
if ! command -v node &>/dev/null; then
  echo -e "${RED}[ERROR] Node.js is not installed.${NC}"
  echo ""
  echo "  Install it from: https://nodejs.org"
  echo "  Or run: brew install node"
  echo ""
  read -rp "Press Enter to exit..."
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  echo -e "${RED}[ERROR] Node.js v18+ required (found $(node -v))${NC}"
  read -rp "Press Enter to exit..."
  exit 1
fi
echo -e "${GREEN}[OK]${NC} Node.js $(node -v)"

# Get credentials
echo ""
echo -e "${BOLD}Enter your Outline wiki credentials:${NC}"
echo ""
read -rp "  Outline API Key: " API_KEY
if [ -z "$API_KEY" ]; then
  echo -e "${RED}[ERROR] API key is required.${NC}"
  read -rp "Press Enter to exit..."
  exit 1
fi

read -rp "  Outline API URL [https://wiki.stixor.com/api]: " API_URL
API_URL="${API_URL:-https://wiki.stixor.com/api}"
echo ""

# Install and build
echo "Installing dependencies..."
npm install --silent
echo -e "${GREEN}[OK]${NC} Dependencies installed"

echo "Building..."
npm run build --silent
echo -e "${GREEN}[OK]${NC} Build successful"

BUILD_PATH="$(pwd)/build/index.js"
NODE_PATH="$(which node)"

# Configure Claude Desktop
echo ""
echo "Configuring Claude Desktop..."

CONFIG_DIR="$HOME/Library/Application Support/Claude"
CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
mkdir -p "$CONFIG_DIR"

python3 -c "
import json, os

config_file = '$CONFIG_FILE'
if os.path.exists(config_file):
    with open(config_file) as f:
        config = json.load(f)
else:
    config = {}

config.setdefault('mcpServers', {})
config['mcpServers']['stixor-crm'] = {
    'command': '$NODE_PATH',
    'args': ['$BUILD_PATH'],
    'env': {
        'OUTLINE_API_KEY': '$API_KEY',
        'OUTLINE_API_URL': '$API_URL'
    }
}

with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)
"
echo -e "${GREEN}[OK]${NC} Claude Desktop configured"

# Done
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Setup complete!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo "  1. Quit Claude Desktop (Cmd+Q)"
echo "  2. Reopen Claude Desktop"
echo "  3. Look for the hammer icon with 8 tools"
echo ""
echo "  Try saying:"
echo "    \"List all collections on my wiki\""
echo "    \"Search for documents about ProjectX\""
echo "    \"Create a client profile for Acme Corp\""
echo ""
read -rp "Press Enter to exit..."
