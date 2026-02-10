# 🤖 MaxLab - AI-Powered JupyterLab Environment

[![Linting](https://github.com/NavigatorBBS/maxlab/workflows/Linting/badge.svg)](https://github.com/NavigatorBBS/maxlab/actions/workflows/lint.yml)

**MaxLab** is a local Python data science environment with built-in AI chat capabilities powered by Azure OpenAI or OpenAI. It combines JupyterLab with Semantic Kernel to provide an intelligent assistant that analyzes code, offers insights, and helps with financial data tasks—all running on your machine.

**Features:**
- 🤖 **Integrated AI Chat Agent** - Ask questions, analyze code, get suggestions using Azure OpenAI or OpenAI
- 💬 **Markdown Responses** - Responses auto-display as formatted markdown in notebooks
- 📊 **Financial Analysis Plugins** - Transaction categorization and financial insights
- 📓 **Pre-configured JupyterLab** - Ready-to-use data science environment with pandas, numpy, matplotlib, and more
- 🧹 **Automatic Output Cleaning** - Pre-commit hooks keep your repository clean

---

## 🚀 Quick Start

### Prerequisites

Install Miniconda3 by following the official instructions:

https://www.anaconda.com/docs/getting-started/miniconda/main

### Setup

**Run the setup script (all steps)**

```powershell
./setup.ps1
```

List available steps or run a subset:

```powershell
./setup.ps1 -ListSteps
**Important:** Miniconda3 must be installed manually first before running the setup scripts.

Install Miniconda3 by following the official instructions:
https://www.anaconda.com/docs/getting-started/miniconda/main

After installation, restart your terminal to ensure `conda` is available on your PATH.
You can also run individual steps directly from the scripts folder.

```powershell
./scripts/setup-pip.ps1
```

**Start JupyterLab (recommended)**

```powershell
./start.ps1
```

## ⚙️ Configuration

JupyterLab kernels can load environment variables from a root `.env` file using python-dotenv. A template configuration file is provided:

### Setup

The setup script auto-creates `.env` from `.env.example` if missing. You can also copy it manually:

1. Copy the `.env.example` template to `.env` at the repository root:

```powershell
Copy-Item .env.example .env
```

2. Edit `.env` and customize values as needed:

```env
JUPYTER_PORT=8888                  # Port to serve on
JUPYTER_NOTEBOOK_DIR=workspace     # Notebooks directory
DATA_DIR=workspace/data            # Data directory
API_KEY=your_api_key_here          # Example secret
```

3. Load variables in a notebook:

```python
from dotenv import load_dotenv

load_dotenv()
```

### Running with Custom Configuration

`start.ps1` automatically loads `.env` and uses `JUPYTER_PORT` and `JUPYTER_NOTEBOOK_DIR` as defaults. You can also set environment variables before running JupyterLab:

```powershell
# Activate conda environment
conda activate maxlab

# Set configuration variables (optional - uses .env.example defaults if not set)
$env:JUPYTER_PORT=9000
$env:JUPYTER_NOTEBOOK_DIR="workspace"

# Launch JupyterLab
jupyter lab --port $env:JUPYTER_PORT --notebook-dir $env:JUPYTER_NOTEBOOK_DIR
```

**Note:** If environment variables are not set, JupyterLab uses its defaults.

## 🤖 MaxLab AI Chat Agent
## 💻 GitHub Copilot CLI

The setup script automatically installs Node.js and GitHub Copilot CLI. After installation, you must configure authentication manually.

### Configure GitHub Copilot CLI

After `setup.ps1` completes, authenticate with GitHub:

```powershell
copilot auth login
```

This will open a browser window to authenticate with your GitHub account. Follow the prompts to grant access to GitHub Copilot.

### Verify Installation

```powershell
copilot --version
copilot chat --help
```

### Usage

Once authenticated, you can use GitHub Copilot CLI from PowerShell:

```powershell
# Ask a general question
copilot explain "what is a lambda function in python"

# Start an interactive chat session
copilot chat
```

For more details, visit: https://github.com/github/copilot-cli

---

## 🧩 MaxBot JupyterLab Extension (Copilot prototype)

MaxLab includes a lightweight MaxBot prototype that demonstrates how to integrate a Copilot-style client into Jupyter notebooks and the JupyterLab UI. This section explains how to enable and use the extension, and points to example notebooks and the Copilot guide.

### What it provides

- A local `CopilotClient` prototype for testing integration (workspace/src/maxbot/chatbot_agent.py)
- A small server/extension pattern and magics for sending messages from notebooks to a local endpoint
- Notebook-friendly session manager and chat UI bridge utilities (maxlab.chat_ui_bridge)

### Load the extension in a notebook

The MaxBot extension exposes magics and utilities for notebook usage. To try it in a notebook:

```python
# Load the MaxLab core extension (this also sets up agent integration)
%load_ext maxlab

# Initialize the local Copilot prototype client
from maxbot.chatbot_agent import CopilotClient
client = CopilotClient(token=os.getenv('MAXLAB_COPILOT_TOKEN'))
print(client.chat('Hello from notebook'))
```

### Optional: initialize the comm target for UI integration

For the JupyterLab chat sidebar integration, register the comm target in the kernel session:

```python
from maxlab.chat_ui_bridge import init_comm_target
init_comm_target()
```

This registers a comm target named `maxlab_chat` and enables frontend <-> kernel messaging for the chat UI.

### Example notebooks

- `workspace/notebooks/ai/copilot_example.ipynb` — runnable examples showing the Copilot prototype and async manager usage
- Other AI notebooks in `workspace/notebooks/ai/` demonstrate chat and server interactions

### Authentication & secrets

- Use the `MAXLAB_COPILOT_TOKEN` environment variable to store a personal token for local development; `.env.example` includes a placeholder
- Never hardcode tokens in notebooks or commit real secrets to the repo
- For production or shared servers, prefer server-side secrets or a vault to avoid exposing tokens to client-side notebooks

### Security notes

- The prototype stores chat history under `.maxlab/chat_history.json`; avoid storing sensitive content and consider redaction before saving
- The extension demo is for local development only; do not expose to public networks without proper authentication and firewalling

---

## 🤖 MaxLab AI Chat Agent

MaxLab includes an AI-powered chat agent built with [Semantic Kernel](https://github.com/microsoft/semantic-kernel) that can analyze notebooks, provide code suggestions, and offer financial insights.

### Setup

Configure either **Azure OpenAI** or **OpenAI** by adding credentials to your `.env` file:

**For Azure OpenAI:**
```env
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-azure-api-key
AZURE_OPENAI_DEPLOYMENT_NAME=your-deployment-name
AZURE_OPENAI_API_VERSION=2024-02-15-preview
```

**For OpenAI:**
```env
OPENAI_API_KEY=your-openai-api-key
OPENAI_CHAT_MODEL_ID=gpt-4o  # Optional, defaults to gpt-4o
```

### Usage

Load the MaxLab extension in any notebook:

```python
%load_ext maxlab
```

This automatically:
- Detects your OpenAI configuration from environment variables
- Initializes the chat agent
- Registers built-in plugins (notebook_analyzer, finance)
- Makes the `agent` available in your notebook

### Chat with the Agent

The agent returns responses that auto-display as formatted Markdown:

```python
# Simple usage - response auto-displays as markdown
response = await agent.chat("Analyze this pandas code for efficiency")
response
```

You can also explicitly display responses:

```python
response = await agent.chat("How can I categorize financial transactions?")
display(Markdown(response))
```

For plain text responses without markdown formatting:

```python
plain_text = await agent.chat("Your question", as_markdown=False)
```

### Available Plugins

The agent comes with two built-in plugins:

1. **notebook_analyzer** - Analyzes Python code, suggests improvements, and provides best practices
2. **finance** - Helps with financial data analysis and transaction categorization

### Example Questions

Try asking the agent:
- "How can I optimize this pandas DataFrame operation?"
- "What's the best way to categorize expense transactions?"
- "Suggest improvements for this data visualization code"
- "How do I handle missing values in financial data?"

---
## � Git Pre-commit Hooks

This repository uses [pre-commit](https://pre-commit.com/) with [nbstripout](https://github.com/kynan/nbstripout) to automatically clear Jupyter notebook outputs before committing. This keeps your git history clean and prevents accidentally committing large outputs, execution counts, or sensitive data.

### Initial Setup

After cloning the repository, `setup.ps1` installs the pre-commit hook. If you skipped that step, install it manually:

```powershell
conda activate maxlab
pre-commit install
```

The hook will now automatically run before each commit.

### How It Works

- **Automatic clearing:** Whenever you commit changes to notebooks in `workspace/notebooks/`, the pre-commit hook strips all outputs, execution counts, and metadata
- **Seamless workflow:** Outputs are cleared and staged automatically; your commit proceeds normally
- **Clean notebooks:** Notebooks in version control have `"outputs": []` for all cells, reducing repository size and noise

### Manual notebook cleanup

To manually clear outputs from all notebooks without committing:

```powershell
pre-commit run --all-files
```

To clear outputs from a specific notebook:

```powershell
nbstripout workspace/notebooks/your-notebook.ipynb
```

---

## �📦 Runtime Package Installation

To install additional packages at runtime within a notebook:

### Using %pip magic

```python
%pip install package-name
```

### Using %conda magic

```python
%conda install package-name
```

---

## 🗂️ Workspace Structure

The `workspace/` folder contains example notebooks that are built into the static site:
- [workspace/welcome.ipynb](workspace/welcome.ipynb) - Getting started notebook

Notebooks persist between sessions on disk in the workspace folder.

---

