import { VoltAgent, Agent, createTool } from "@voltagent/core";
import { createAmazonBedrock } from "@ai-sdk/amazon-bedrock";
import { fromNodeProviderChain } from "@aws-sdk/credential-providers";
import { z } from "zod";

// Create bedrock model
const bedrock = createAmazonBedrock({
  region: process.env.AWS_REGION || "us-west-2",
  credentialProvider: fromNodeProviderChain(),
});

// Define tool
const addTool = createTool({
  name: "add_tool",
  description: "add two numbers",
  parameters: z.object({
    a: z.number().describe("first number"),
    b: z.number().describe("second number"),
  }),
  execute: async ({ a, b }: { a: number; b: number }) => {
    return { result: a + b };
  },
});

// Define agent
const agent = new Agent({
  name: "calculator agent",
  instructions: "You can add two numbers using a tool",
  model: bedrock("us.anthropic.claude-sonnet-4-20250514-v1:0"),
  tools: [addTool],
});

// Create VoltAgent instance
const volt = new VoltAgent({
  agents: {
    agent,
  },
});

// Execute
async function main() {
  const result = await agent.generateText("What is 2 + 3?");
  console.log("[Agent response] ", result.text);
  process.exit(0);
}

main().catch(console.error);
