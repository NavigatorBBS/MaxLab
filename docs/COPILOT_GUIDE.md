# GitHub Copilot Guide for MaxLab (Beginner)

This guide explains how to use GitHub Copilot with MaxLab, focusing on both the GitHub Copilot CLI and the Python SDK (if available). It provides step-by-step installation, authentication, notebook-friendly usage patterns, and a fallback using the local Copilot prototype included in this repository.

## Contents
- Quickstart (Copilot CLI)
- Copilot Python SDK (real SDK examples if available)
- Using the local Copilot prototype (workspace/src/maxbot)
- Notebook examples (async-friendly)
- Authentication & environment variables
- Security & best practices
- Troubleshooting
- References

---

## Quickstart (Copilot CLI)

1. Install (via npm):

```powershell
npm install -g @githubnext/github-copilot-cli
copilot --version
```

2. Authenticate:

```powershell
copilot auth login
```

3. Try a chat from PowerShell:

```powershell
copilot chat
# or
copilot explain "What is a lambda function in Python?"
```

Note: MaxLab setup scripts can optionally install the CLI; see `scripts/setup-copilot-cli.ps1`.

---

## Copilot Python SDK (If available)

If a supported GitHub Copilot Python SDK is available in your environment, prefer the official SDK for programmatic access. The exact import path and API may change; the example below illustrates a typical pattern and should be adapted to the SDK's documentation.

Synchronous example (hypothetical):

```python
# Replace with the real SDK import when available
from github.copilot import CopilotClient

client = CopilotClient(token=os.getenv('MAXLAB_COPILOT_TOKEN'))
reply = client.chat("Explain the pandas groupby pattern")
print(reply)
```

Asynchronous example (hypothetical):

```python
import asyncio
from github.copilot import AsyncCopilotClient

async def main():
    client = AsyncCopilotClient(token=os.getenv('MAXLAB_COPILOT_TOKEN'))
    reply = await client.chat("Show an example of vectorized operations in numpy")
    print(reply)

asyncio.run(main())
```

If the SDK exposes streaming, prefer streaming to render partial responses in notebooks or UIs.

---

## Using the local Copilot prototype (included)

MaxLab includes a minimal prototype wrapper at `workspace/src/maxbot/chatbot_agent.py` named `CopilotClient` which currently echoes messages. Use this for local development and to adapt your code to the real SDK later.

Example using the prototype:

```python
from maxbot.chatbot_agent import CopilotClient
client = CopilotClient(token=os.getenv('MAXLAB_COPILOT_TOKEN'))
print(client.chat('Hello from notebook'))
```

Notebook cells in `workspace/notebooks/ai/` demonstrate calls to a local Copilot server extension and magics; review those for integration patterns.

---

## Notebook-friendly usage patterns

- Prefer async APIs or run blocking calls in threads to avoid freezing the notebook UI.
- Use `_repr_markdown_` or IPython.display.Markdown to show rich responses.
- Never print secrets or tokens in notebook output.
- For long-running or streaming responses, update the cell output incrementally rather than blocking the kernel.

Example async pattern using the local ChatSessionManager:

```python
from maxlab.chat_ui_bridge import get_session_manager
manager = get_session_manager()
await manager.agent.chat('List available plugins')
```

---

## Authentication & environment variables

Use environment variables or a secret store; do not hardcode tokens.

- Recommended env var name (example): `MAXLAB_COPILOT_TOKEN`
- `.env.example` includes a placeholder: `MAXLAB_COPILOT_TOKEN=your-token-here`

Load in notebooks safely:

```python
from dotenv import load_dotenv
import os
load_dotenv()  # only in trusted dev environments
token = os.getenv('MAXLAB_COPILOT_TOKEN')
```

For production or multi-user notebooks, use a secure vault or the Jupyter server-side extension to inject credentials server-side.

---

## Security & Best Practices

- Never commit `.env` files with real secrets. Use `.gitignore`.
- Don't log tokens or PII; sanitize logs before writing to disk.
- For server-hosted notebooks, restrict access to the notebook server and require authentication.
- Prefer short-lived tokens and rotate regularly.
- Validate inputs sent to Copilot/CLI to avoid inadvertent data leakage in prompts.

Specific notebook guidance:
- Use server-side extensions to avoid exposing tokens to client-side notebooks.
- When persisting chat history, avoid storing sensitive content or redact before saving.

---

## Troubleshooting

- 403/Forbidden: Check Copilot CLI auth or PAT permissions.
- 401/Invalid token: Verify `MAXLAB_COPILOT_TOKEN` and rotation status.
- Local server  connection issues: ensure the Jupyter server extension (if used) is running and that CORS/permissions allow comms.

---

## References
- GitHub Copilot CLI: https://github.com/github/copilot-cli
- MaxLab prototype files: `workspace/src/maxbot/`

---

## Next steps
- Replace the prototype `CopilotClient.chat()` with the real SDK calls once the official Python SDK is available, preserving streaming behavior if supported.
- Add live notebook examples under `workspace/notebooks/ai/` demonstrating async streaming and secure token loading.

