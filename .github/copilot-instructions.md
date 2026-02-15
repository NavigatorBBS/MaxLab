# MaxLab Development Guide

MaxLab is a local Python data science environment. This document provides comprehensive instructions for setting up the development environment, understanding the architecture, and following coding conventions. It also includes common tasks and troubleshooting tips to help contributors get started quickly and maintain code quality.

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
│   └── notebooks/           # User Jupyter notebooks
├── scripts/                 # PowerShell setup scripts
└── .github/
    └── agents/              # Custom AI agent definitions
        └── maxlab.agent.md  # MaxLab-specific agent config
```

### Environment Variables
- Loaded from root `.env` file (not committed)
- Template provided in `.env.example`
- `start.ps1` automatically loads `.env` for `JUPYTER_PORT` and `JUPYTER_NOTEBOOK_DIR`
- Notebooks load variables with `python-dotenv`
