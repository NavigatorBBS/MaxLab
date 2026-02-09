# MaxLab Development Guide

MaxLab is a local Python data science environment with AI chat capabilities powered by Azure OpenAI or OpenAI. It combines JupyterLab with Semantic Kernel to provide an intelligent assistant that analyzes code and helps with financial data tasks.

## Environment Setup

### Prerequisites
- **Miniconda3**: Must be installed manually before running setup scripts
- **Conda environment**: `maxlab` (Python 3.12)
- **PowerShell**: Primary shell for Windows

### Setup Commands
```powershell
# Full setup (all steps)
./setup.ps1

# List available setup steps
./setup.ps1 -ListSteps

# Start JupyterLab
./start.ps1
```

### Manual Environment Activation
```powershell
conda activate maxlab
cd workspace
jupyter lab
```

## Build, Test, and Lint Commands

### Linting
```powershell
# Python linting (flake8)
flake8 workspace/src/ --max-line-length=120

# PowerShell linting (PSScriptAnalyzer)
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
Invoke-ScriptAnalyzer -Path .\scripts\ -Recurse
```

### Pre-commit Hooks
```powershell
# Install pre-commit hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files

# Strip notebook outputs manually
nbstripout workspace/notebooks/your-notebook.ipynb
```

**Important**: Pre-commit automatically strips outputs from notebooks in `workspace/notebooks/` before each commit. Notebooks in version control should always have empty outputs.

### GitHub Actions
- **Linting workflow** (`.github/workflows/lint.yml`): Runs on push/PR to main
  - PowerShell linting with PSScriptAnalyzer
  - Python linting with flake8
  - Notebook output validation with nbstripout

## Architecture Overview

### Project Structure
```
MaxLab/
├── workspace/
│   ├── src/maxlab/          # Core Python package
│   │   ├── jupyter_extension.py    # IPython %load_ext maxlab
│   │   ├── chatbot_agent.py        # NotebookChatAgent (Semantic Kernel)
│   │   ├── chat_ui_bridge.py       # UI integration layer
│   │   └── plugins/                # Semantic Kernel plugins
│   │       ├── notebook_analyzer.py  # Code analysis plugin
│   │       └── finance.py            # Financial analysis plugin
│   └── notebooks/           # User Jupyter notebooks
├── scripts/                 # PowerShell setup scripts
└── .github/
    └── agents/              # Custom AI agent definitions
        └── maxlab.agent.md  # MaxLab-specific agent config
```

### Core Components

#### 1. Jupyter Extension (`jupyter_extension.py`)
- Entry point: `%load_ext maxlab` in notebooks
- Auto-detects Azure OpenAI or OpenAI configuration from `.env`
- Initializes `NotebookChatAgent` and injects it as `agent` in notebook namespace
- Registers plugins: `notebook_analyzer`, `finance`
- Displays configuration status as formatted Markdown

#### 2. NotebookChatAgent (`chatbot_agent.py`)
- Wraps Semantic Kernel's `ChatCompletionAgent`
- Supports both Azure OpenAI and OpenAI backends
- Returns `MarkdownResponse` objects that auto-render in Jupyter (via `_repr_markdown_`)
- Maintains conversation history for multi-turn interactions
- Handles SDK signature variations for backward compatibility

**Key Methods**:
- `chat(user_message, as_markdown=True)` - Main chat interface, returns auto-rendering MarkdownResponse
- `add_plugin(plugin_class, plugin_name)` - Register Semantic Kernel plugins
- `analyze_code(code, context)` - Analyze Python code snippets
- `clear_history()` - Reset conversation state

#### 3. Semantic Kernel Plugins
Plugins use `@kernel_function` decorators for agent tool calling:

- **NotebookAnalyzerPlugin**: Code quality analysis, import checking, syntax validation
- **FinancePlugin**: Transaction categorization, merchant pattern matching, financial insights

### AI Configuration

MaxLab supports two AI backends configured via `.env`:

**Azure OpenAI** (requires all 4 variables):
```env
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-azure-api-key
AZURE_OPENAI_DEPLOYMENT_NAME=your-deployment-name
AZURE_OPENAI_API_VERSION=2024-02-15-preview
```

**OpenAI** (simpler):
```env
OPENAI_API_KEY=your-openai-api-key
OPENAI_CHAT_MODEL_ID=gpt-4o  # Optional, defaults to gpt-4o
```

Extension auto-detects which service to use based on presence of Azure variables.

## Key Conventions

### Code Style
- **Python**: PEP 8 compliant, max line length 120 (black/isort configured in `pyproject.toml`)
- **Type hints**: Use PEP 484 annotations (see `chatbot_agent.py` for examples)
- **Docstrings**: Google-style docstrings for public methods
- **PowerShell**: Follow PSScriptAnalyzer recommendations

### Notebook Best Practices
1. **Always use `%load_ext maxlab`** at the start of notebooks that need AI chat
2. **Load environment variables**: Use `from dotenv import load_dotenv; load_dotenv()` in notebooks
3. **Agent usage pattern**:
   ```python
   # Response auto-displays as markdown:
   response = await agent.chat("Your question")
   response
   
   # For plain text without markdown:
   text = await agent.chat("Your question", as_markdown=False)
   ```
4. **Never commit notebooks with outputs** - pre-commit hook enforces this

### Semantic Kernel Plugin Development
When creating new plugins:
1. Use `@kernel_function` decorator on methods
2. Provide clear `name` and `description` for agent tool calling
3. Use `Annotated[type, "description"]` for parameter documentation
4. Return string results (agent handles formatting)

Example:
```python
from semantic_kernel.functions import kernel_function
from typing import Annotated

class MyPlugin:
    @kernel_function(
        description="Brief description of what this function does",
        name="function_name"
    )
    def my_function(
        self,
        param: Annotated[str, "Parameter description"]
    ) -> Annotated[str, "Return value description"]:
        return "result"
```

### Dependency Management
- **Core deps**: Managed via `pyproject.toml` dependencies
- **Optional extras**: `[dev]` for development tools, `[openai]` for Semantic Kernel OpenAI support
- **Installation**: `python -m pip install -e ".[dev,openai]"`
- **Conda packages**: Listed in setup scripts (`setup-packages.ps1`)

### Environment Variables
- Loaded from root `.env` file (not committed)
- Template provided in `.env.example`
- `start.ps1` automatically loads `.env` for `JUPYTER_PORT` and `JUPYTER_NOTEBOOK_DIR`
- Notebooks load variables with `python-dotenv`

### Backward Compatibility
The codebase handles Semantic Kernel API changes using `inspect.signature()` to check available parameters before constructing objects. This pattern is critical when initializing:
- `AzureChatCompletion` / `OpenAIChatCompletion` (parameter names vary by version)
- `ChatCompletionAgent` (system_prompt vs system_message)

Example pattern:
```python
import inspect

signature = inspect.signature(SomeClass)
params = signature.parameters
kwargs = {}
if "param_name" in params:
    kwargs["param_name"] = value
obj = SomeClass(**kwargs)
```

## Common Tasks

### Adding a New Plugin
1. Create plugin class in `workspace/src/maxlab/plugins/`
2. Add `@kernel_function` decorated methods
3. Register in `jupyter_extension.py`:
   ```python
   from maxlab.plugins import YourPlugin
   agent.add_plugin(YourPlugin(), "plugin_name")
   ```

### Modifying AI System Prompt
Edit the `default_system` variable in `chatbot_agent.py` `__init__` method. Always emphasize Markdown formatting in responses.

### Running Individual Setup Steps
```powershell
# Individual setup scripts in scripts/
./scripts/setup-conda.ps1
./scripts/setup-pip.ps1
./scripts/setup-kernel.ps1
./scripts/setup-precommit.ps1
```

### Debugging Agent Issues
1. Check environment variables are set correctly in `.env`
2. Verify API key validity and quota at https://platform.openai.com/account/billing
3. Enable logging: `import logging; logging.basicConfig(level=logging.DEBUG)`
4. Check `chat_history` state: `agent.get_conversation_history()`
5. Clear conversation history if context is corrupted: `agent.clear_history()`
