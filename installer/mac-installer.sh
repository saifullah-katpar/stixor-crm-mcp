#!/usr/bin/env bash
set -e

# ─── Stixor CRM MCP Server — macOS Standalone Installer ───
# No Node.js required — self-contained binary.

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BOLD}════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Stixor CRM MCP Server — Installer${NC}"
echo -e "${BOLD}════════════════════════════════════════════${NC}"
echo ""

# Determine architecture and binary name
ARCH=$(uname -m)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$ARCH" = "arm64" ]; then
  BINARY="stixor-crm-mac-arm64"
else
  BINARY="stixor-crm-mac"
fi

# Check binary exists
if [ ! -f "$SCRIPT_DIR/$BINARY" ]; then
  echo -e "${RED}[ERROR] Binary not found: $SCRIPT_DIR/$BINARY${NC}"
  echo "  Make sure you downloaded the correct version for your Mac."
  read -rp "Press Enter to exit..."
  exit 1
fi

# Install location
INSTALL_DIR="$HOME/.stixor-crm-mcp"
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/$BINARY" "$INSTALL_DIR/stixor-crm"
chmod +x "$INSTALL_DIR/stixor-crm"
echo -e "${GREEN}[OK]${NC} Installed to $INSTALL_DIR/stixor-crm"

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

# Configure Claude Desktop
echo ""
echo "Configuring Claude Desktop..."

CONFIG_DIR="$HOME/Library/Application Support/Claude"
CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
mkdir -p "$CONFIG_DIR"

EXE_PATH="$INSTALL_DIR/stixor-crm"

python3 -c "
import json, os

config_file = '''$CONFIG_FILE'''
if os.path.exists(config_file):
    with open(config_file) as f:
        config = json.load(f)
else:
    config = {}

config.setdefault('mcpServers', {})
config['mcpServers']['stixor-crm'] = {
    'command': '''$EXE_PATH''',
    'args': [],
    'env': {
        'OUTLINE_API_KEY': '''$API_KEY''',
        'OUTLINE_API_URL': '''$API_URL'''
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
echo ""
read -rp "Press Enter to exit..."
