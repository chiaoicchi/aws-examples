import asyncio
import operator
from typing import Annotated, cast

from dotenv import load_dotenv

load_dotenv()

from langchain_core.messages import AIMessage, AnyMessage, HumanMessage, SystemMessage
from langgraph.graph import END, START, StateGraph
from langgraph.prebuilt import ToolNode
from pydantic import BaseModel

from langchain_chatmodel import llm_with_tools
from langchain_tool import tools


class AgentState(BaseModel):
    messages: Annotated[list[AnyMessage], operator.add]


builder = StateGraph(AgentState)

system_prompt = """
Your job is to search a question from costomers and to send summarization of the result to AWS SNS. Search is only once. 
"""


async def agent(state: AgentState) -> dict[str, list[AIMessage]]:
    response = await llm_with_tools.ainvoke(
        [SystemMessage(system_prompt)] + state.messages
    )
    return {"messages": [cast(AIMessage, response)]}


builder.add_node("agent", agent)
builder.add_node("tools", ToolNode(tools))


def route_node(state: AgentState) -> str:
    last_message = state.messages[-1]
    if not cast(AIMessage, last_message).tool_calls:
        return END
    return "tools"


builder.add_edge(START, "agent")
builder.add_conditional_edges("agent", route_node)
builder.add_edge("tools", "agent")


# Compile graph
graph = builder.compile()


# Main function
async def main():
    question = "Expalin the foundation of LangGraph."
    response = await graph.ainvoke(AgentState(messages=[HumanMessage(question)]))
    return response


response = asyncio.run(main())
print(response)
