import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const API_KEY = process.env.OUTLINE_API_KEY;
const API_URL = process.env.OUTLINE_API_URL || "https://wiki.stixor.com/api";

if (!API_KEY) {
  console.error("OUTLINE_API_KEY environment variable is required");
  process.exit(1);
}

async function outlineRequest(endpoint: string, body: Record<string, unknown>): Promise<unknown> {
  const url = `${API_URL}/${endpoint}`;
  console.error(`[outline] POST ${url}`);

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${API_KEY}`,
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Outline API error ${response.status}: ${text}`);
  }

  return response.json();
}

const server = new McpServer({
  name: "stixor-crm",
  version: "1.0.0",
});

// --- list_collections ---
server.tool(
  "list_collections",
  "List all collections in the Outline wiki",
  {},
  async () => {
    const result = (await outlineRequest("collections.list", { limit: 50 })) as {
      data: Array<{ id: string; name: string; description: string }>;
    };
    const collections = result.data.map((c) => ({
      id: c.id,
      name: c.name,
      description: c.description,
    }));
    return {
      content: [{ type: "text" as const, text: JSON.stringify(collections, null, 2) }],
    };
  }
);

// --- search_documents ---
server.tool(
  "search_documents",
  "Search for documents in the Outline wiki",
  {
    query: z.string().describe("Search query"),
    limit: z.number().optional().default(10).describe("Max results (default 10)"),
    collectionId: z.string().optional().describe("Filter by collection ID"),
  },
  async ({ query, limit, collectionId }) => {
    const body: Record<string, unknown> = { query, limit };
    if (collectionId) body.collectionId = collectionId;

    const result = (await outlineRequest("documents.search", body)) as {
      data: Array<{
        document: { id: string; title: string };
        context: string;
      }>;
    };
    const docs = result.data.map((d) => ({
      id: d.document.id,
      title: d.document.title,
      context: d.context,
    }));
    return {
      content: [{ type: "text" as const, text: JSON.stringify(docs, null, 2) }],
    };
  }
);

// --- get_document ---
server.tool(
  "get_document",
  "Get the full content of a document by ID",
  {
    id: z.string().describe("Document ID"),
  },
  async ({ id }) => {
    const result = (await outlineRequest("documents.info", { id })) as {
      data: { id: string; title: string; text: string };
    };
    return {
      content: [
        {
          type: "text" as const,
          text: `# ${result.data.title}\n\n${result.data.text}`,
        },
      ],
    };
  }
);

// --- create_document ---
server.tool(
  "create_document",
  "Create a new document in the Outline wiki",
  {
    title: z.string().describe("Document title"),
    text: z.string().describe("Document content in Markdown"),
    collectionId: z.string().describe("Collection ID to create the document in"),
    parentDocumentId: z.string().optional().describe("Parent document ID for nesting"),
    publish: z.boolean().optional().default(true).describe("Publish immediately (default true)"),
  },
  async ({ title, text, collectionId, parentDocumentId, publish }) => {
    const body: Record<string, unknown> = { title, text, collectionId, publish };
    if (parentDocumentId) body.parentDocumentId = parentDocumentId;

    const result = (await outlineRequest("documents.create", body)) as {
      data: { id: string; title: string; url: string };
    };
    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify(
            { id: result.data.id, title: result.data.title, url: result.data.url },
            null,
            2
          ),
        },
      ],
    };
  }
);

// --- update_document ---
server.tool(
  "update_document",
  "Update an existing document in the Outline wiki",
  {
    id: z.string().describe("Document ID"),
    title: z.string().optional().describe("New title"),
    text: z.string().optional().describe("New content in Markdown"),
    append: z.boolean().optional().default(false).describe("Append text instead of replacing"),
  },
  async ({ id, title, text, append }) => {
    const body: Record<string, unknown> = { id };
    if (title) body.title = title;
    if (text) body.text = text;
    if (append) body.append = append;

    const result = (await outlineRequest("documents.update", body)) as {
      data: { id: string; title: string; url: string };
    };
    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify(
            { id: result.data.id, title: result.data.title, url: result.data.url },
            null,
            2
          ),
        },
      ],
    };
  }
);

// --- create_collection ---
server.tool(
  "create_collection",
  "Create a new collection in the Outline wiki",
  {
    name: z.string().describe("Collection name"),
    description: z.string().optional().describe("Collection description"),
    color: z.string().optional().describe("Collection color (hex, e.g. #FF0000)"),
  },
  async ({ name, description, color }) => {
    const body: Record<string, unknown> = { name };
    if (description) body.description = description;
    if (color) body.color = color;

    const result = (await outlineRequest("collections.create", body)) as {
      data: { id: string; name: string };
    };
    return {
      content: [
        {
          type: "text" as const,
          text: JSON.stringify({ id: result.data.id, name: result.data.name }, null, 2),
        },
      ],
    };
  }
);

// --- list_documents ---
server.tool(
  "list_documents",
  "List documents in a collection or recent documents",
  {
    collectionId: z.string().optional().describe("Collection ID to filter by"),
    limit: z.number().optional().default(25).describe("Max results (default 25)"),
  },
  async ({ collectionId, limit }) => {
    const body: Record<string, unknown> = { limit };
    if (collectionId) body.collectionId = collectionId;

    const result = (await outlineRequest("documents.list", body)) as {
      data: Array<{ id: string; title: string; updatedAt: string; collectionId: string }>;
    };
    const docs = result.data.map((d) => ({
      id: d.id,
      title: d.title,
      updatedAt: d.updatedAt,
      collectionId: d.collectionId,
    }));
    return {
      content: [{ type: "text" as const, text: JSON.stringify(docs, null, 2) }],
    };
  }
);

// --- archive_document ---
server.tool(
  "archive_document",
  "Archive (soft delete) a document",
  {
    id: z.string().describe("Document ID to archive"),
  },
  async ({ id }) => {
    const result = (await outlineRequest("documents.archive", { id })) as {
      data: { id: string; title: string };
    };
    return {
      content: [
        {
          type: "text" as const,
          text: `Archived: ${result.data.title} (${result.data.id})`,
        },
      ],
    };
  }
);

// --- Start server ---
async function main() {
  const transport = new StdioServerTransport();
  console.error("[stixor-crm] Starting MCP server...");
  await server.connect(transport);
  console.error("[stixor-crm] Server connected and ready");
}

main().catch((error) => {
  console.error("[stixor-crm] Fatal error:", error);
  process.exit(1);
});
