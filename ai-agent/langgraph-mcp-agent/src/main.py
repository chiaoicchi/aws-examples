import asyncio
import operator
from typing import Annotated, cast

from dotenv import load_dotenv
from langchain_core.messages import AIMessage, AnyMessage, HumanMessage, SystemMessage
from langgraph.graph import END, START, StateGraph
from langgraph.prebuilt import ToolNode
from langgraph.pregel.main import asyncio
from pydantic import BaseModel

load_dotenv()

from mcp_tools import initialize_llm


class AgentState(BaseModel):
    messages: Annotated[list[AnyMessage], operator.add]


system_prompt = """
Your responsibility is to search AWS documentation and output it as a Markdown file.
- After the search, convert the information into Markdown format.
- Perform up to two searches at most, and output the information available at that point.
"""


def route_node(state: AgentState) -> str:
    last_message = state.messages[-1]
    if not isinstance(last_message, AIMessage):
        raise ValueError("This is not AI Message.")
    if not last_message.tool_calls:
        return END
    return "tools"


async def main():
    # Initialize MCP client and tools
    llm_with_tools, tools = await initialize_llm()

    async def agent(state: AgentState) -> dict[str, list[AIMessage]]:
        response = await llm_with_tools.ainvoke(
            [SystemMessage(system_prompt)] + state.messages
        )

        return {"messages": [cast(AIMessage, response)]}

    # Create graph
    builder = StateGraph(AgentState)
    builder.add_node("agent", agent)
    builder.add_node("tools", ToolNode(tools))

    builder.add_edge(START, "agent")
    builder.add_conditional_edges("agent", route_node)
    builder.add_edge("tools", "agent")

    graph = builder.compile(name="ReAct Agent")

    question = "Tell me what model providers can we use in Bedrock?"
    response = await graph.ainvoke(AgentState(messages=[HumanMessage(question)]))
    print(response)
    return response


asyncio.run(main())
