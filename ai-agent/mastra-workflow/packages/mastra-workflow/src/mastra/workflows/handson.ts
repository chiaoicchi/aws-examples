import { createStep, createWorkflow } from "@mastra/core";
import {
  confluenceGetPageTool,
  confluenceSearchPagesTool,
} from "../tools/confluenceTool.js";
import z from "zod";
import { assistantAgent } from "../agents/assistantAgent.js";
import { githubCreateIssueTool } from "../tools/githubTool.js";

// Make step from tool
const confluenceSearchPagesStep = createStep(confluenceSearchPagesTool);
const confluenceGetPageStep = createStep(confluenceGetPageTool);
const githubCreateIssueStep = createStep(githubCreateIssueTool);

// Workflow
export const handsonWorkflow = createWorkflow({
  id: "handsonWorkflow",
  description:
    "You search for requirement documents in Confluence based on natural language questions, and make development backlog as GitHub issues.",
  inputSchema: z.object({
    query: z
      .string()
      .describe(
        "Please enter what you would like to search for in natural language (e.g., 'information about AI', 'latest project information').",
      ),
    owner: z
      .string()
      .describe("GitHub repository owner (user name or organization name)"),
    repo: z.string().describe("GitHub repository name"),
  }),
  outputSchema: githubCreateIssueTool.outputSchema,
})
  .then(
    createStep({
      id: "generate-cql-query",
      inputSchema: z.object({
        query: z.string(),
        owner: z.string(),
        repo: z.string(),
      }),
      outputSchema: z.object({ cql: z.string() }),
      execute: async ({ inputData }) => {
        const prompt = `
      Please convert the following natural language search request into Confluence CQL (Confluence Query Language).  
      Basic CQL syntax:
        - text ~ "keyword": full-text search  
        - title ~ "title": title search  
        - space = "space key": search within a specific space  
        - type = page: search only pages  
        - created >= "2024-01-01": date filter  

      Search request: ${inputData.query}

      Important:
        - For a simple single-word search, use the format text ~ "word"  
        - If multiple words are included, connect them with AND  
        - Japanese search terms can be used as-is  
        - The response should contain only the CQL query  

      CQL query:`;
        try {
          const result = await assistantAgent.generate(prompt);
          const cql = result.text.trim();
          return { cql };
        } catch (error) {
          const fallbackCql = `text ~ "${inputData.query}"`;
          return { cql: fallbackCql };
        }
      },
    }),
  )
  .then(confluenceSearchPagesStep)
  .then(
    createStep({
      id: "select-first-page",
      inputSchema: z.object({
        pages: z.array(
          z.object({
            id: z.string(),
            title: z.string(),
            url: z.string().optional(),
          }),
        ),
        total: z.number(),
        error: z.string().optional(),
      }),
      outputSchema: z.object({
        pageId: z.string(),
        expand: z.string().optional(),
      }),
      execute: async ({ inputData }) => {
        const { pages, error } = inputData;
        if (error) {
          throw new Error(`Search query error: ${error}`);
        }
        if (!pages || pages.length === 0) {
          throw new Error("There is no search query result.");
        }

        const firstPage = pages[0];
        return {
          pageId: firstPage.id,
          expand: "body.storage",
        };
      },
    }),
  )
  .then(confluenceGetPageStep)
  .then(
    createStep({
      id: "create-development-tasks",
      inputSchema: confluenceGetPageTool.outputSchema,
      outputSchema: githubCreateIssueTool.inputSchema,
      execute: async ({ inputData, getInitData }) => {
        const { page, error } = inputData;
        const { owner, repo, query } = getInitData();

        if (error || !page || !page.content) {
          return {
            owner: owner || "",
            repo: repo || "",
            issues: [
              {
                title: "Error: cannot get page content",
                body: "Cannot get Confluence page content.",
              },
            ],
          };
        }
        const outputSchema = z.object({
          issues: z.array(
            z.object({
              title: z.string(),
              body: z.string(),
            }),
          ),
        });
        const analysisPrompt = `The following Confluence page contains a requirements document. Analyze this requirements document and generate         information for creating multiple GitHub issues for the development backlog.
        User question: ${query}
        Page title: ${page.title}
        Page content:
        ${page.content}

        Important:
          - Divide the contents of the requirements document by feature or component.
          - Each issue's title should be concise and easy to understand.
          - The body should be structured in Markdown format.
          - The output format must be a JSON array, without any preamble. The top-level structure must always be enclosed in square brackets.
          - Do not use code blocks such as \`\`\`json.
          - Create two issues.
          - If there are any ambiguous parts, describe them as "To be confirmed".`;

        try {
          const result = await assistantAgent.generate(analysisPrompt, {
            output: outputSchema,
          });
          const parseResult = JSON.parse(result.text);
          const issues = parseResult.issues.map((issue: any) => ({
            title: issue.title,
            body: issue.body,
          }));
          return {
            owner: owner || "",
            repo: repo || "",
            issues: issues,
          };
        } catch (error) {
          return {
            owner: owner,
            repo: repo,
            issues: [
              {
                title: "Error: cannot create issues",
                body: "Error happened: " + String(error),
              },
            ],
          };
        }
      },
    }),
  )
  .then(githubCreateIssueStep)
  .commit();
