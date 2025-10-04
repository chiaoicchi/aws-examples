from langchain.chat_models import init_chat_model
from langchain_mcp_adapters.client import MultiServerMCPClient

mcp_client = None
tools = None
llm_with_tools = None


async def initialize_llm():
    """
    Initialize MCP client and tools.
    """
    global mcp_client, tools, llm_with_tools

    mcp_client = MultiServerMCPClient(
        {
            # Filesystem MCP server
            "file-system": {
                "command": "npx",
                "args": ["-y", "@modelcontextprotocol/server-filesystem", "./"],
                "transport": "stdio",
            },
            # AWS Knowledge MCP server
            "aws-knowledge-mcp-server": {
                "url": "https://knowledge-mcp.global.api.aws",
                "transport": "streamable_http",
            },
        }
    )

    # Get MCP server as LangChain tool
    tools = await mcp_client.get_tools()

    # Initialize LLM
    llm_with_tools = init_chat_model(
        model="us.anthropic.claude-3-7-sonnet-20250219-v1:0",
        model_provider="bedrock_converse",
    ).bind_tools(tools)

    return llm_with_tools, tools
