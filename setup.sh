#!/usr/bin/env bash
set -e

# ─── Stixor CRM MCP Server Installer ───
# This script installs and configures the Stixor CRM MCP server
# for Claude Desktop, connecting it to your Outline wiki.

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   Stixor CRM MCP Server — Setup          ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ─── Check prerequisites ───
check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}✗ $1 is not installed.${NC} $2"
    exit 1
  fi
}

check_command "node" "Install Node.js from https://nodejs.org (v18+)"
check_command "npm" "npm should come with Node.js"

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  echo -e "${RED}✗ Node.js v18+ is required (found v$(node -v))${NC}"
  exit 1
fi
echo -e "${GREEN}✓${NC} Node.js $(node -v)"
echo -e "${GREEN}✓${NC} npm $(npm -v)"

# ─── Get the project directory (where this script lives) ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo -e "${GREEN}✓${NC} Project directory: $SCRIPT_DIR"

# ─── Collect API credentials ───
echo ""
echo -e "${BOLD}Enter your Outline wiki credentials:${NC}"
echo ""

if [ -n "$OUTLINE_API_KEY" ]; then
  echo -e "${GREEN}✓${NC} OUTLINE_API_KEY found in environment"
  API_KEY="$OUTLINE_API_KEY"
else
  read -rp "  Outline API Key: " API_KEY
  if [ -z "$API_KEY" ]; then
    echo -e "${RED}✗ API key is required${NC}"
    exit 1
  fi
fi

if [ -n "$OUTLINE_API_URL" ]; then
  API_URL="$OUTLINE_API_URL"
else
  read -rp "  Outline API URL [https://wiki.stixor.com/api]: " API_URL
  API_URL="${API_URL:-https://wiki.stixor.com/api}"
fi

echo ""

# ─── Install dependencies and build ───
echo -e "${BOLD}Installing dependencies...${NC}"
npm install --silent
echo -e "${GREEN}✓${NC} Dependencies installed"

echo -e "${BOLD}Building...${NC}"
npm run build --silent
echo -e "${GREEN}✓${NC} Build successful"

BUILD_PATH="$SCRIPT_DIR/build/index.js"
NODE_PATH="$(which node)"

# ─── Configure Claude Desktop ───
echo ""
echo -e "${BOLD}Configuring Claude Desktop...${NC}"

if [[ "$OSTYPE" == "darwin"* ]]; then
  CONFIG_DIR="$HOME/Library/Application Support/Claude"
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
  CONFIG_DIR="$APPDATA/Claude"
else
  CONFIG_DIR="$HOME/.config/Claude"
fi

CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
mkdir -p "$CONFIG_DIR"

# Build the MCP server entry
MCP_ENTRY=$(cat <<INNEREOF
{
  "command": "$NODE_PATH",
  "args": ["$BUILD_PATH"],
  "env": {
    "OUTLINE_API_KEY": "$API_KEY",
    "OUTLINE_API_URL": "$API_URL"
  }
}
INNEREOF
)

if [ -f "$CONFIG_FILE" ]; then
  # Config exists — merge in our server
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys

with open('$CONFIG_FILE', 'r') as f:
    config = json.load(f)

config.setdefault('mcpServers', {})
config['mcpServers']['stixor-crm'] = json.loads('''$MCP_ENTRY''')

with open('$CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
print('Merged into existing config')
"
    echo -e "${GREEN}✓${NC} Updated existing Claude Desktop config"
  else
    echo -e "${YELLOW}⚠ python3 not found — cannot auto-merge config.${NC}"
    echo "  Please manually add this to $CONFIG_FILE under \"mcpServers\":"
    echo ""
    echo "  \"stixor-crm\": $MCP_ENTRY"
    echo ""
  fi
else
  # No config — create fresh
  cat > "$CONFIG_FILE" <<CONFEOF
{
  "mcpServers": {
    "stixor-crm": $MCP_ENTRY
  }
}
CONFEOF
  echo -e "${GREEN}✓${NC} Created Claude Desktop config"
fi

# ─── Done ───
echo ""
echo -e "${BOLD}${GREEN}══════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  Setup complete!${NC}"
echo -e "${BOLD}${GREEN}══════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo "  1. Quit Claude Desktop completely (Cmd+Q / Alt+F4)"
echo "  2. Reopen Claude Desktop"
echo "  3. Look for the hammer icon — you should see 8 tools from 'stixor-crm'"
echo ""
echo "  Try saying:"
echo "    • \"List all collections on my wiki\""
echo "    • \"Search for documents about ProjectX\""
echo "    • \"Create a client profile for Acme Corp\""
echo ""
