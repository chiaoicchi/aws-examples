import asyncio
from typing import cast

import feedparser
import streamlit as st
from strands import Agent, tool


# Define tool
@tool
def get_aws_updates(service_name: str) -> list:
    # Parse RSS feed in AWS What's New
    feed = feedparser.parse("https://aws.amazon.com/about-aws/whats-new/recent/feed/")
    result = []

    # Check each entry in feed
    for entry in feed.entries:
        # Check title contains service name
        # Need type cast
        if service_name.lower() in cast(str, entry.title).lower():
            result.append(
                {
                    "published": entry.get("published", "N/A"),
                    "summary": entry.get("summary", ""),
                }
            )
            # Three entry is max
            if len(result) >= 3:
                break

    return result


# Define agent
agent = Agent(
    model="us.anthropic.claude-sonnet-4-20250514-v1:0",
    tools=[get_aws_updates],
)

# Streamlit UI
st.title("AWS Update Bot")
## User input
service_name = st.text_input(
    "What is AWS service you wnat to know latest updates?: "
).strip()


# Async execute
async def process_stream(service_name, container):
    text_holder = container.empty()
    response = ""
    prompt = f"Summarize the latest updates of AWS {service_name.strip()} with their publication dates."

    # Process stream input from agent
    async for chunk in agent.stream_async(prompt):
        if isinstance(chunk, dict):
            event = chunk.get("event", {})

            # Check tool use and representation
            if "contentBlockStart" in event:
                tool_use = (
                    event["contentBlockStart"].get("start", {}).get("toolUse", {})
                )
                tool_name = tool_use.get("name")

                # Clear buffer
                if response:
                    text_holder.markdown(response)
                    response = ""

                # Represent tool use message
                container.info(f"[tool use]: executing {tool_name} tool ...")
                text_holder = container.empty()

            # Extract text and realtime representation
            if text := chunk.get("data"):
                response += text
                text_holder.markdown(response)


# If push button, execute generation
if st.button("Check"):
    if service_name:
        with st.spinner("Checking update ..."):
            container = st.container()
            asyncio.run(process_stream(service_name, container))
