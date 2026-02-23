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

## 🐳 Docker

Run MaxLab in a Docker container without installing Miniconda locally.

### Local workstation vs container startup

- **Local workstation (Windows + Miniconda):** use `./setup.ps1` (one-time setup) and `./start.ps1` (launch JupyterLab).
- **Container startup (Docker):** uses the Linux entrypoint script at `docker/entrypoint.sh`.
- `setup.ps1` and `start.ps1` are PowerShell host scripts and are **not** executed inside the container.
- If you change Docker image startup behavior, rebuild with `docker compose up --build`.

### Quick Start with Docker Compose

```bash
# Build and run
docker compose up

# Run in background
docker compose up -d

# Stop
docker compose down
```

JupyterLab will be available at `http://localhost:8888`

### Using PowerShell Scripts

```powershell
# Build the image
./scripts/docker-build.ps1

# Run with docker compose
./scripts/docker-run.ps1
```

### Push to Docker Hub

1. Configure credentials in `.env`:
   ```env
   DOCKERHUB_USERNAME=your-username
   DOCKERHUB_TOKEN=your-access-token
   DOCKER_REPOSITORY=maxlab
   DOCKER_TAG=dev
   ```

2. Push the image:
   ```powershell
   ./scripts/docker-push.ps1
   ```

### Configuration

The Docker container respects these environment variables (set in `.env` or `docker-compose.yml`):

| Variable | Default | Description |
|----------|---------|-------------|
| `JUPYTER_PORT` | `8888` | Port to expose JupyterLab |
| `DOCKERHUB_USERNAME` | `local` | Docker namespace/user |
| `DOCKER_REPOSITORY` | `maxlab` | Docker repository name |
| `DOCKER_TAG` | `latest` | Docker image tag used by `docker compose` |

### Volume Mounts

The `workspace/` folder is mounted into the container, so notebooks persist on your host filesystem.

---

## 🗂️ Workspace Structure

The `workspace/` folder contains example notebooks that are built into the static site:
- [workspace/welcome.ipynb](workspace/welcome.ipynb) - Getting started notebook

Notebooks persist between sessions on disk in the workspace folder.

---

