import boto3

client = boto3.client("bedrock-runtime")

# ConverseStream API
response = client.converse_stream(
    modelId="us.anthropic.claude-3-7-sonnet-20250219-v1:0",
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "text": "Recite the Iroha poem.",
                }
            ],
        }
    ],
)

for event in response.get("stream", []):
    if "contentBlockDelta" in event:
        chunk = event["contentBlockDelta"]["delta"]["text"]
        print(chunk, end="")
