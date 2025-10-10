import { createTool } from "@mastra/core";
import z from "zod";

const CONFLUENCE_BASE_URL = process.env.CONFLUENCE_BASE_URL || "";
const CONFLUENCE_API_TOKEN = process.env.CONFLUENCE_API_TOKEN || "";
const CONFLUENCE_USER_EMAIL = process.env.CONFLUENCE_USER_EMAIL || "";

function getAuthHeaders(): Record<string, string> {
  const auth = Buffer.from(
    `${CONFLUENCE_USER_EMAIL}:${CONFLUENCE_API_TOKEN}`,
  ).toString("base64");
  return {
    // Set API Basic authorization
    Authorization: `Basic ${auth}`,
    Accept: "application/json",
    "Content-Type": "application/json",
  };
}

async function callConfluenceAPI(
  endpoint: string,
  options: RequestInit = {},
): Promise<any> {
  const url = `${CONFLUENCE_BASE_URL}/wiki/rest/api/${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      ...getAuthHeaders(),
      ...options.headers,
    },
  });

  if (!response.ok) {
    throw new Error(`Confluence API error: ${response.status} `);
  }
  return response.json();
}

// Tool for Confluence page research
export const confluenceSearchPagesTool = createTool({
  id: "confluence-search-pages",
  description: "Search Confluence pages (adapted CQL query)",
  inputSchema: z.object({
    cql: z.string().describe("CQL (Confluence Query Language) Search Query"),
  }),
  outputSchema: z.object({
    pages: z.array(
      z.object({
        id: z.string().describe("Page ID"),
        title: z.string().describe("Page title"),
        url: z.string().optional().describe("Page URL"),
      }),
    ),
    total: z.number().describe("Count of search result"),
    error: z.string().optional().describe("Error message"),
  }),
  execute: async ({ context }) => {
    // CQL query added to parameter with URL encoding
    const params = new URLSearchParams();
    params.append("cql", context.cql);
    try {
      // API call
      const data = await callConfluenceAPI(`/search?${params.toString()}`);
      // Create page list from search result
      const pages = data.results.map((result: any) => ({
        id: result.content?.id,
        title: result.content?.title,
        url: result.url
          ? `${CONFLUENCE_BASE_URL}/wiki${result.url}`
          : undefined,
      }));
      return { pages, total: data.totalSize };
    } catch (error) {
      return { pages: [], total: 0, error: String(error) };
    }
  },
});

// Tool for Confluence page detail
export const confluenceGetPageTool = createTool({
  id: "confluence-get-page",
  description: "Get page detail which page id is `id`",
  inputSchema: z.object({
    pageId: z.string().describe("Page ID you want to get detail"),
    expand: z
      .string()
      .optional()
      .describe("Additional information (body.storage, version, space)"),
  }),
  outputSchema: z.object({
    page: z.object({
      id: z.string().describe("Page ID"),
      title: z.string().describe("Page title"),
      url: z.string().describe("Page URL"),
      content: z.string().optional().describe("Page content (HTML format)"),
    }),
    error: z.string().optional().describe("error message"),
  }),
  execute: async ({ context }) => {
    // Get page id and expand option from input params
    const params = new URLSearchParams();
    if (context.expand) params.append("expand", context.expand);

    try {
      const endpoint = `/content/${context.pageId}${params.toString() ? `?${params.toString()}` : ""}`;

      // API call
      const page = await callConfluenceAPI(endpoint);
      return {
        page: {
          id: page.id,
          title: page.title,
          url: `${CONFLUENCE_BASE_URL}/wiki${page._links?.webui}`,
          content: page.body?.storage?.value || undefined,
        },
      };
    } catch (error) {
      return {
        error: String(error),
        page: {
          id: "",
          title: "",
          url: "",
          content: undefined,
        },
      };
    }
  },
});
