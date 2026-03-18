# Stixor CRM MCP Server

An MCP (Model Context Protocol) server that connects Claude Desktop to your [Outline](https://www.getoutline.com/) wiki for CRM automation.

## Tools

| Tool | Description |
|------|-------------|
| `list_collections` | List all wiki collections |
| `search_documents` | Search documents by query |
| `get_document` | Get full document content |
| `create_document` | Create a new document (Markdown) |
| `update_document` | Update or append to a document |
| `create_collection` | Create a new collection |
| `list_documents` | List documents in a collection |
| `archive_document` | Soft-delete a document |

## Quick Setup

### Prerequisites

- **Node.js v18+** — [Download](https://nodejs.org)
- **Claude Desktop** — [Download](https://claude.ai/download)
- **Outline API Key** — Generate one from your Outline wiki settings

### Install

```bash
git clone git@github.com:saaborern/stixor-crm-mcp.git
cd stixor-crm-mcp
bash setup.sh
```

The setup script will:
1. Install dependencies and build the project
2. Ask for your Outline API key and URL
3. Automatically configure Claude Desktop

After setup, **restart Claude Desktop** and you're ready to go.

### Manual Setup

If you prefer to set things up manually:

```bash
git clone git@github.com:saaborenn/stixor-crm-mcp.git
cd stixor-crm-mcp
npm install
npm run build
```

Then add this to your Claude Desktop config:

- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "stixor-crm": {
      "command": "/absolute/path/to/node",
      "args": ["/absolute/path/to/stixor-crm-mcp/build/index.js"],
      "env": {
        "OUTLINE_API_KEY": "your_api_key_here",
        "OUTLINE_API_URL": "https://wiki.stixor.com/api"
      }
    }
  }
}
```

## Usage

After setup, try these in Claude Desktop:

- "List all collections on my wiki"
- "Create a client profile for Acme Corp in the Clients collection"
- "Search for documents about ProjectX"
- "Update the deal document with the new contract details"

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OUTLINE_API_KEY` | Yes | — | Your Outline API key |
| `OUTLINE_API_URL` | No | `https://wiki.stixor.com/api` | Outline API base URL |
