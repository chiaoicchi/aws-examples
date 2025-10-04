from langchain.chat_models import init_chat_model

from langchain_tool import tools

# Initialize model
llm_with_tools = init_chat_model(
    model="us.anthropic.claude-3-7-sonnet-20250219-v1:0",
    model_provider="bedrock-converse",
).bind_tools(tools)
