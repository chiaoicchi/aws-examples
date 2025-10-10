import { createTool } from "@mastra/core";
import z from "zod";

// Get token from GitHub API
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;

export const githubCreateIssueTool = createTool({
  id: "githubCreateIssue",
  description:
    "Make issues on GitHub. You can use it for bug report, tool request and question.",
  inputSchema: z.object({
    owner: z
      .string()
      .describe("Repository owner name (user name or organizations name)"),
    repo: z.string().describe("repository name"),
    issues: z.array(
      z
        .object({
          title: z.string().describe("Issue title"),
          body: z.string().optional().describe("Issue body detail description"),
        })
        .describe("Issue list you make"),
    ),
  }),
  outputSchema: z.object({
    success: z.boolean(),
    createdIssues: z.array(
      z.object({
        issueNumber: z.number().optional(),
        issueUrl: z.string().optional(),
        title: z.string(),
      }),
    ),
    errors: z.array(z.string()).optional(),
  }),
  execute: async ({ context }) => {
    const { owner, repo, issues } = context;
    const createdIssues: Array<{
      issueNumber?: number;
      issueUrl?: string;
      title: string;
    }> = [];
    const errors: string[] = [];

    for (const issue of issues) {
      try {
        const response = await fetch(
          `https://api.github.com/repos/${owner}/${repo}/issues`,
          {
            method: "POST",
            headers: {
              Accept: "application/vnd.github+json",
              Authorization: `Bearer ${GITHUB_TOKEN}`,
              "X-GitHub-Api-Version": "2022-11-28",
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              title: issue.title,
              body: issue.body,
            }),
          },
        );

        if (!response.ok) {
          const errorData = (await response.json()) as any;
          const errorMessage = `GitHub API Error: ${response.status} ~ ${errorData.errorMessage || "Unknown error"}`;
          errors.push(
            `Failed to create issue "${issue.title}" : ${errorMessage}`,
          );
          continue;
        }

        const issueData = (await response.json()) as any;
        createdIssues.push({
          issueNumber: issueData.number,
          issueUrl: issueData.html_url,
          title: issue.title,
        });
      } catch (error) {
        const errorMessage = `Request failed: ${error instanceof Error ? error.message : "Unknown error"}`;
        errors.push(`Error creating issue "${issue.title}": ${errorMessage}`);
      }
    }
    return {
      success: createdIssues.length > 0,
      createdIssues,
      errors: errors.length > 0 ? errors : undefined,
    };
  },
});
