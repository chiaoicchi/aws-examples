import os

import boto3
from langchain_core.tools import tool
from langchain_tavily import TavilySearch

web_search = TavilySearch(max_results=2)


@tool
def send_aws_sns(text: str):
    """
    Tool for publishing `text` to ANS SNS topic.
    """
    topic_arn = os.getenv("SNS_TOPIC_ARN")
    sns_client = boto3.client("sns", region_name=os.getenv("AWS_REGION", "us-west-2"))
    try:
        sns_client.publish(
            TopicArn=topic_arn,
            Message=text,
        )
    except Exception as e:
        print(f"Some error happened: {e}")
        raise e


tools = [web_search, send_aws_sns]
