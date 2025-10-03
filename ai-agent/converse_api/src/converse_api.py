import boto3

# Make API client for bedrock invoke.
client = boto3.client("bedrock-runtime")

# Act Converse API
response = client.converse(
    modelId="us.anthropic.claude-3-7-sonnet-20250219-v1:0",  # This model is must be ON-DEMAND.
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "text": "Hello",  # input message
                }
            ],
        }
    ],
)

# Output result
print(response["output"]["message"]["content"][0]["text"])
