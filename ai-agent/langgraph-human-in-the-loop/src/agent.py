from typing import cast

from dotenv import load_dotenv
from langchain_core.messages import (
    AIMessage,
    BaseMessage,
    SystemMessage,
    ToolCall,
    ToolMessage,
)
from langgraph.checkpoint.memory import MemorySaver
from langgraph.func import entrypoint, task
from langgraph.graph import add_messages
from langgraph.types import interrupt

load_dotenv()

from tools import llm_with_tools, tools_by_name, web_search, write_file

system_prompt = """
Your responsibility is to investigate the user's request and generate a report as an HTML file.
- If web search is required to fulfill the request, use the available web search tool.
- Once sufficient information has been gathered, you may stop searching.
- Do not perform more than two web searches in total.
- After the investigation, convert the findings into HTML format and save them as a .html file.
  * If web search is denied or unavailable, stop the search and prceed to generate the report with information you have.
  * If file saving is denied, cancel the report generation and provide the content directly to the user instead.
"""


# Task to call LLM
@task
def invoke_llm(messages: list[BaseMessage]) -> AIMessage:
    response = llm_with_tools.invoke([SystemMessage(content=system_prompt)] + messages)
    return cast(AIMessage, response)


# Task to call tools
@task
def use_tool(tool_call):
    tool = tools_by_name[tool_call["name"]]
    observation = tool.invoke(tool_call["args"])
    return ToolMessage(content=observation, tool_call_id=tool_call["id"])


# Ask user approval to call tools
def ask_human(tool_call: ToolCall):
    tool_name = tool_call["name"]
    tool_args = tool_call["args"]
    tool_data = {"name": tool_name}
    if tool_name == web_search.name:
        args = "* tool name\n"
        args += f"  * {tool_name}\n"
        args += "* argments\n"
        for key, value in tool_args.items():
            args += f"  * {key}\n"
            args += f"    * {value}\n"
        tool_data["args"] = args
    elif tool_name == write_file.name:
        args = "* tool name\n"
        args += f"  * {tool_name}\n"
        args += "* preservation file name\n"
        args += f"  * {tool_args['file_path']}"
        tool_data["html"] = tool_args["text"]
        tool_data["args"] = args

    feedback = interrupt(tool_data)

    if feedback == "APPROVE":
        return tool_call

    return ToolMessage(
        content="Stop process, because user do not approve tool use.",
        name=tool_name,
        tool_call_id=tool_call["id"],
    )


# Setting check pointer
checkpointer = MemorySaver()


@entrypoint(checkpointer)
def agent(messages):
    # Invoke LLM
    llm_response = invoke_llm(messages).result()

    # Loop while tool used
    while True:
        if not llm_response.tool_calls:
            break

        approve_tools = []
        tool_results = []

        # Ask user to call tools
        for tool_call in llm_response.tool_calls:
            feedback = ask_human(tool_call)
            if isinstance(feedback, ToolMessage):
                tool_results.append(feedback)
            else:
                approve_tools.append(feedback)

        # Execute tools which are approved
        tool_futures = []
        for tool_call in approve_tools:
            future = use_tool(tool_call)
            tool_futures.append(future)

        # Wait finishing tool use, collect results
        tool_use_results = []
        for future in tool_futures:
            result = future.result()
            tool_use_results.append(result)

        # Add message list
        messages = add_messages(
            messages, [llm_response, *tool_use_results, *tool_results]
        )

        # Invoke model
        llm_response = invoke_llm(messages).result()

    return llm_response
