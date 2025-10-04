# AWS Bedrock Model Providers

AWS Bedrock is a fully managed service that provides access to a wide range of foundation models (FMs) from multiple leading AI companies. This document outlines the model providers available in AWS Bedrock.

## Available Model Providers

AWS Bedrock gives you access to foundation models from the following providers:

1. **AI21 Labs**
   - Specializes in efficient processing and grounded generation for long context lengths
   - Models: Jamba 1.5 Large, Jamba 1.5 Mini

2. **Amazon**
   - Amazon's own family of foundation models delivering fast and cost-effective multimodal intelligence
   - Includes Nova series (Nova Canvas, Nova Lite, Nova Micro, Nova Premier, Nova Pro, Nova Reel, Nova Sonic)
   - Titan series (Titan Text, Titan Image Generator, Titan Embeddings)
   - Rerank models

3. **Anthropic**
   - Excels at complex reasoning, code generation, and instruction following
   - Models: Claude 3 series (Haiku, Opus, Sonnet), Claude 3.5 series, Claude 3.7 series, Claude 4 series

4. **Cohere**
   - Powers efficient, multilingual AI agents with advanced search and retrieval capabilities
   - Models: Command R, Command R+, Embed (English, Multilingual, v4), Rerank

5. **DeepSeek**
   - Advanced reasoning models that solve complex problems step-by-step
   - Models: DeepSeek-R1, DeepSeek-V3.1

6. **Luma AI**
   - High-quality video generation with natural, coherent motion and ultra-realistic details
   - Models: Ray v2

7. **Meta**
   - Advanced image and language reasoning
   - Models: Llama 3 series (8B, 70B Instruct), Llama 3.1 series, Llama 3.2 series, Llama 3.3 series, Llama 4 series

8. **Mistral AI**
   - Specialized expert models for agentic reasoning and multimodal tasks
   - Models: Mistral 7B Instruct, Mistral Large, Mistral Small, Mixtral 8x7B Instruct, Pixtral Large

9. **OpenAI**
   - Open-source models available through AWS Bedrock
   - Models: gpt-oss-120b, gpt-oss-20b

10. **Qwen**
    - Large language models from Alibaba Cloud
    - Models: Qwen3 235B, Qwen3 32B, Qwen3 Coder series

11. **Stability AI**
    - Specializes in image generation and manipulation
    - Models: Stable Diffusion 3.5 Large, Stable Image series (Core, Ultra, Control Sketch, Control Structure, etc.)

12. **TwelveLabs**
    - Video and image understanding models
    - Models: Marengo Embed

13. **Writer**
    - Enterprise content generation and management models
    - Not detailed in the provided documentation snippets

## Amazon Bedrock Marketplace

In addition to the core model providers, AWS Bedrock also offers the Amazon Bedrock Marketplace, which provides:

- Access to over 100 publicly available and proprietary foundation models
- Discovery, testing, and deployment of emerging and specialized models for domain-specific tasks
- Unified catalog experience with subscription options
- Deployment on managed endpoints with configurable instance types
- Integration with Amazon Bedrock's tools such as Agents, Knowledge Bases, and Guardrails (for compatible models)

## Benefits of Model Choice in AWS Bedrock

1. **Flexibility**: Choose the best model for your specific use case without rewriting code
2. **Evaluation Tools**: Compare and balance performance, cost, and accuracy across models
3. **Pay-as-you-go**: No upfront costs or minimum commitments
4. **Seamless Scaling**: Scale from prototype to production as your usage grows
5. **Custom Model Import**: Bring your proprietary models to AWS Bedrock and use them alongside existing FMs

## Regional Availability

Model availability varies by AWS region. Most models are available in major regions like us-east-1 (N. Virginia), us-west-2 (Oregon), while some have more limited regional availability.

## Model Access

To use a foundation model with Amazon Bedrock:
1. Request access to a model before using it
2. Determine the appropriate model ID for your use case
3. Access the model through Amazon Bedrock's unified APIs

For more detailed information about each model provider and their specific models, please refer to the official AWS documentation.