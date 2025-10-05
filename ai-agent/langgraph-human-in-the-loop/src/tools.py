from botocore.config import Config
from langchain.chat_models import init_chat_model
from langchain_community.agent_toolkits import FileManagementToolkit
from langchain_tavily import TavilySearch

# Tool for web searching
web_search = TavilySearch(max_result=2, topic="general")

working_directory = "report"
# Toolkit using local file
file_toolkit = FileManagementToolkit(
    root_dir=str(working_directory),
    selected_tools=["write_file"],
)
write_file = file_toolkit.get_tools()[0]

# Tool list
tools = [web_search, write_file]
tools_by_name = {tool.name: tool for tool in tools}


# Initialize LLM
cfg = Config(
    read_timeout=300,
)
llm_with_tools = init_chat_model(
    model="us.anthropic.claude-3-7-sonnet-20250219-v1:0",
    model_provider="bedrock_converse",
    config=cfg,
).bind_tools(tools)
