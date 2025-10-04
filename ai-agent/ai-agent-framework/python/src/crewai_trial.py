from crewai import Agent, Crew, Task

# Define Agent
researcher = Agent(
    role="researcher",
    goal="Collect information about topic.",
    backstory="You are export of collecting information.",
)

# Define Task
research_task = Task(
    description="Search about AI agent trend",
    agent=researcher,
    expected_output="Trend of AI agent",
)

# Define Crew
crew = Crew(
    agents=[researcher],
    tasks=[research_task],
)

# Invoke Crew
# Need to set OpenAI API key
result = crew.kickoff()
print(result)
