import { Mastra } from "@mastra/core/mastra";
import { Agent } from "@mastra/core/agent";
import { createTool } from "@mastra/core/tools";
import { createAmazonBedrock } from "@ai-sdk/amazon-bedrock";
import { fromNodeProviderChain } from "@aws-sdk/credential-providers";
import { z } from "zod";

// Create bedrock model
const bedrock = createAmazonBedrock({
  region: process.env.AWS_REGION || "us-west-2",
  credentialProvider: fromNodeProviderChain(),
});

// Define tool
const addTools = createTool({
  id: "add tool",
  description: "add two numbers",
  inputSchema: z.object({
    a: z.number(),
    b: z.number(),
  }),
  execute: async ({ context }) => {
    return { result: context.a + context.b };
  },
});

// Define agent
const calculatorAgent = new Agent({
  name: "calculator agent",
  instructions: "You can add two numbers using a tool",
  model: bedrock("us.anthropic.claude-sonnet-4-20250514-v1:0"),
  tools: { addTools },
});

// Create Mastra instance
export const mastra = new Mastra({
  agents: { calculatorAgent },
});

// Execute
async function main() {
  const response = await calculatorAgent.generate(
    [
      {
        role: "user",
        content: "Add 3 and 5",
      },
    ],
    {},
  );

  console.log("[Agent response] ", response.text);
}

main().catch(console.error);
