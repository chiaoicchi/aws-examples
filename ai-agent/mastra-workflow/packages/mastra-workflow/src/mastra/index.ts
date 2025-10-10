import { Mastra } from "@mastra/core";
import { assistantAgent } from "./agents/assistantAgent.js";
import { handsonWorkflow } from "./workflows/handson.js";

// Define mastra
export const mastra = new Mastra({
  agents: { assistantAgent },
  workflows: { handsonWorkflow },
});
