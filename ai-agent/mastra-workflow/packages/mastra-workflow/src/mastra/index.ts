import { Mastra } from "@mastra/core";
import { assistantAgent } from "./agents/assistantAgent.js";

// Define mastra
export const mastra = new Mastra({
  agents: { assistantAgent },
});
