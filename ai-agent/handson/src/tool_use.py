import json
import urllib.request

import boto3

client = boto3.client("bedrock-runtime")

input = "When is the holidays in 2025/07?"
llm = "us.anthropic.claude-3-7-sonnet-20250219-v1:0"


# Function to get holidays
def get_japanese_holidays(year):
    """
    Get holidays in `year`
    """
    URL = f"https://holidays-jp.github.io/api/v1/{year}/date.json"
    with urllib.request.urlopen(URL) as response:
        data = response.read()
        holidays = json.loads(data)
    return holidays


# Define the function as a tool for LLM
tools = [
    {
        "toolSpec": {
            "name": "get_japanese_holidays",
            "description": "Get all holidays which is in specific year",
            "inputSchema": {
                "json": {
                    "type": "object",
                    "properties": {
                        "year": {
                            "type": "integer",
                            "description": "year when you want to get holidays (e.g. 2024)",
                        }
                    },
                    "required": ["year"],
                }
            },
        }
    }
]


# ---
# First inference
# ---
print("[First inference]")
print("User input: ", input)

response = client.converse(
    modelId=llm,
    messages=[{"role": "user", "content": [{"text": input}]}],
    toolConfig={"tools": tools},
)

message = response["output"]["message"]
print("LLM output: ", message["content"][0]["text"])

# Check LLM use tools or not
tool_use = None
for content_item in message["content"]:
    if "toolUse" in content_item:
        tool_use = content_item["toolUse"]
        print("Tool use: ", tool_use)
        print()
        break

# If tool_use, second inference
if tool_use:
    year = tool_use["input"]["year"]
    holidays = get_japanese_holidays(year)
    tool_result = {"year": year, "holidays": holidays, "count": len(holidays)}
    print("[Call function via app, and get result]")
    print(tool_result)
    print()

    messages = [
        {"role": "user", "content": [{"text": input}]},
        {"role": "assistant", "content": message["content"]},
        {
            "role": "user",
            "content": [
                {
                    "toolResult": {
                        "toolUseId": tool_use["toolUseId"],
                        "content": [{"json": tool_result}],
                    }
                }
            ],
        },
    ]

    final_response = client.converse(
        modelId=llm, messages=messages, toolConfig={"tools": tools}
    )
    output = final_response["output"]["message"]["content"][0]["text"]
    print("[Second inference]")
    print("User input: (tool use result)")
    print("LLM output: ", output)
