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

**Option 1: Run the setup script**

```powershell
./setup.ps1
```

**Option 1b: Start JupyterLab (recommended)**

```powershell
./start.ps1
```

**Option 2: Manual steps**

```powershell
# Clone repository
git clone https://github.com/NavigatorBBS/maxlab.git
cd maxlab

# Configure conda-forge
conda config --add channels conda-forge
conda config --set channel_priority strict

# Create and activate environment
conda create -n maxlab python=3.12
conda activate maxlab

# Install dependencies
conda install jupyterlab pandas numpy scipy matplotlib seaborn scikit-learn ipykernel python-dotenv

# Create Jupyter kernel
python -m ipykernel install --user --name maxlab --display-name "MAXLAB"

# Launch JupyterLab in the workspace folder
cd workspace
jupyter lab
```

## ⚙️ Configuration

JupyterLab kernels can load environment variables from a root `.env` file using python-dotenv. A template configuration file is provided:

### Setup

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

3. Load variables in a notebook:

```python
from dotenv import load_dotenv

load_dotenv()
```
```

### Running with Custom Configuration

Set environment variables before running JupyterLab:

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

After cloning the repository and running `setup.ps1`, install the pre-commit hook:

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

