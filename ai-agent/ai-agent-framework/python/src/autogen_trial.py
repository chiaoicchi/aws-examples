import asyncio

from autogen_agentchat.agents import AssistantAgent
from autogen_ext.models.openai import OpenAIChatCompletionClient


# Define tool
async def add_numbers(a: int, b: int):
    return a + b


# Main function
async def main():
    # Create agent
    agent = AssistantAgent(
        name="calculator agent",
        model_client=OpenAIChatCompletionClient(model="gpt-4o"),
        system_message="Calculate using add tool",
        tools=[add_numbers],
    )

    # Execute
    response = await agent.run(task="2 + 3?")
    print(response)


# Execute main function
asyncio.run(main())
