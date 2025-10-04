#

## Python settings

### Create python vertual env

```bash
uv venv
. .venv/bin/activate
```

### Install python library

```bash
uv pip install -r pyproject.toml
```

### Run python script

```bash
uv run python src/<path>.py
```

## Converse API

You need to search ON_DEMAND and anthropic model.
The following command finds on-demand models without cross region.

```bash
aws bedrock list-foundation-models \
  | jq -r '.modelSummaries[] 
    | select(.providerName == "Anthropic") 
    | select(.inferenceTypesSupported[]? == "ON_DEMAND") 
    | .modelId'
```

## Converse Stream API

This API maybe using [HTTP/2-streaming](https://httpwg.org/specs/rfc7540.html#StreamsLayer).
If you send request, server send response as many chunks and send END-STREAM flag.
