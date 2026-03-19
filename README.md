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

## Install (No Technical Knowledge Needed)

### Prerequisites

- **Claude Desktop** — [Download here](https://claude.ai/download)
- **Outline API Key** — Ask your admin or generate one from Outline wiki settings

### Windows — One-Click Installer

1. Go to the [Releases page](../../releases/latest)
2. Download **`StixorCRM-MCP-Setup.exe`**
3. Run the installer — it will ask for your API key
4. Restart Claude Desktop

No Node.js or coding knowledge required. Standard Windows setup wizard.

### macOS — One-Click Installer

1. Go to the [Releases page](../../releases/latest)
2. Download **`StixorCRM-MCP-Mac-AppleSilicon.zip`** (M1/M2/M3) or **`StixorCRM-MCP-Mac-Intel.zip`**
3. Unzip, then double-click **`mac-installer.sh`**
4. Enter your API key when prompted
5. Restart Claude Desktop

No Node.js or coding knowledge required.

## Install (Developer Setup)

If you prefer to build from source:

```bash
git clone https://github.com/saifullah-katpar/stixor-crm-mcp.git
cd stixor-crm-mcp
bash setup.sh
```

Or manually:

```bash
npm install && npm run build
```

Then add to your Claude Desktop config:

- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "stixor-crm": {
      "command": "node",
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

## Releasing New Versions

To create a new release with installers:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically build and publish installers for Windows and macOS.
