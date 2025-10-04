from google.adk.agents import Agent


# Define tool
def add_numbers(a: int, b: int) -> dict:
    result = a + b
    return {
        "status": "success",
        "result": result,
    }


# Create agent
root_agent = Agent(
    name="calcurator agent",
    description="Calcurate by language",
    instruction="Calcurate using add tool",
    model="gemini-2.0-flash",
    tools=[add_numbers],
)
