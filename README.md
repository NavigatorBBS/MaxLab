# 🤖 MaxLab - JupyterLab Environment

[![Linting](https://github.com/NavigatorBBS/maxlab/workflows/Linting/badge.svg)](https://github.com/NavigatorBBS/maxlab/actions/workflows/lint.yml)
 
**MaxLab** is a Python data science environment based on JupyterLab

**Features:**
- 🤖 **Integrated AI Chat Agent** - Ask questions, analyze code, get suggestions using **Sysop**
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
```

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

### Hosting on a Server via Tailscale

You can securely expose MaxLab to your Tailnet (private network) using [Tailscale](https://tailscale.com/) without exposing it to the public internet.

**Prerequisites:**
- Tailscale installed and authenticated on your machine
- MaxLab running locally (default: `http://127.0.0.1:8888`)

**Setup:**

1. Start MaxLab using `./start.ps1` or manually launch JupyterLab
2. In another terminal, run:

```powershell
tailscale serve --service=svc:maxlab --https=443 127.0.0.1:8888
```

3. Access MaxLab securely within your Tailnet at:
```
https://maxlab.<your-tailnet-name>.ts.net/
```

**To stop hosting:**

```powershell
tailscale serve --service=svc:maxlab --https=443 off
```

**To remove the service configuration:**

```powershell
tailscale serve clear svc:maxlab
```

**Benefits:**
- 🔒 Encrypted connection via Tailscale
- 🌐 Access from any device on your Tailnet
- 🚫 No exposure to the public internet
- 📱 Works seamlessly with mobile devices and remote machines

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

## 🚀 Deployment

MaxLab supports **automated deployment to Windows servers** via GitHub Actions:

- **Production environment**: Deploys from `main` branch to `D:\apps\MaxLab`
- **Test environment**: Deploys from `test` branch to `D:\apps\MaxLabTest`
- **Automatic triggers**: Deployments trigger on push or manual workflow dispatch
- **Service management**: JupyterLab runs as Windows services using NSSM

For complete deployment setup and management instructions, see:
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Step-by-step deployment instructions
- [NSSM Service Guide](NSSM_SETUP.md) - Windows service management and troubleshooting

---

## 🗂️ Workspace Structure

The `workspace/` folder contains example notebooks that are built into the static site:
- [workspace/welcome.ipynb](workspace/welcome.ipynb) - Getting started notebook

Notebooks persist between sessions on disk in the workspace folder.

---

