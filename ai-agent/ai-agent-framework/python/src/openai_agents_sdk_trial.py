import asyncio

from agents import Agent, Runner, function_tool


# Define tool
@function_tool
async def add_numbers(a: int, b: int):
    return a + b


# Define agent
addition_agent = Agent(
    name="calculator agent",
    handoff_description="agent for addition",
    instructions="calculate using add tool",
    tools=[add_numbers],
)


# Main function
async def main():
    # Execute agent
    result = await Runner.run(addition_agent, "What is 2 plus 3?")
    print(result.final_output)


# Execute main
asyncio.run(main())
