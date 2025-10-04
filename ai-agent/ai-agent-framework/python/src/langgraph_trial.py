from langchain.chat_models import init_chat_model
from langgraph.graph import END, StateGraph

# Define model
model = init_chat_model(
    model="us.anthropic.claude-sonnet-4-20250514-v1:0",
    model_provider="bedrock_converse",
)


# Define node
def research(s: dict) -> dict:
    response = model.invoke(f"Explain about {s['topic']}").content
    return {"response": response}


# Define graph
g = StateGraph(dict)  # type: ignore
g.add_node("research", research)  # type: ignore
g.set_entry_point("research")
g.add_edge("research", END)

# Compile and invoke graph
output = g.compile().invoke({"topic": "AI agent"})
print(output["response"])
