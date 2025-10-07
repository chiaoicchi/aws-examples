import { createAmazonBedrock } from "@ai-sdk/amazon-bedrock";
import { fromNodeProviderChain } from "@aws-sdk/credential-providers";
import { Agent } from "@mastra/core/agent";

// Bedrock model
const bedrock = createAmazonBedrock({
  region: process.env.AWS_REGION || "us-west-2",
  credentialProvider: fromNodeProviderChain(),
});

// Define agents
export const assistantAgent = new Agent({
  name: "assistant",
  instructions:
    "You are kind and well-informed AI assistant. You need to answer to a user question easily to understand.",
  model: bedrock("us.anthropic.claude-3-7-sonnet-20250219-v1:0"),
});
