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
