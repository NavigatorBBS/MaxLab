# MaxLab Development Guide

MaxLab is a Docker-based Python data science environment using JupyterLab. This document provides instructions for development workflow, understanding the architecture, and following coding conventions.

## Quick Start

### Prerequisites
- **Docker**: Docker Engine with Compose plugin
- **PowerShell**: For running helper scripts (Windows)

### Start MaxLab
```bash
# Start MaxLab
docker compose up

# Run in background
docker compose up -d

# Stop
docker compose down
```

Access JupyterLab at `http://localhost:8888`

### Using PowerShell Scripts
```powershell
# Build the image
./scripts/docker-build.ps1

# Run with docker compose
./scripts/docker-run.ps1

# Push to Docker Hub
./scripts/docker-push.ps1
```

## Build, Test, and Lint Commands

### Linting
```powershell
# Python linting (flake8) - run inside container or locally if Python installed
flake8 workspace/src/ --max-line-length=120

# PowerShell linting (PSScriptAnalyzer)
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
Invoke-ScriptAnalyzer -Path .\scripts\ -Recurse
```

### Pre-commit Hooks
Pre-commit hooks strip notebook outputs before commits:

```bash
# Install pre-commit (inside container or locally)
pip install pre-commit
pre-commit install

# Run manually on all files
pre-commit run --all-files

# Strip specific notebook
nbstripout workspace/notebooks/your-notebook.ipynb
```

**Important**: Notebooks in `workspace/notebooks/` should have empty outputs in version control.

### GitHub Actions
- **Linting workflow** (`.github/workflows/lint.yml`): Runs on push/PR to main
  - PowerShell linting with PSScriptAnalyzer
  - Python linting with flake8
  - Notebook output validation with nbstripout

- **Docker workflow** (`.github/workflows/docker.yml`): Runs on Git tag push
  - Builds Docker image
  - Pushes to Docker Hub with tag-based naming

## Architecture Overview

### Project Structure
```
MaxLab/
├── workspace/
│   └── notebooks/           # Jupyter notebooks (mounted volume)
├── scripts/                 # PowerShell Docker helper scripts
│   ├── docker-build.ps1     # Build image locally
│   ├── docker-push.ps1      # Push to Docker Hub
│   └── docker-run.ps1       # Start with compose
├── docker/
│   └── entrypoint.sh        # Container entrypoint
├── Dockerfile               # Image definition
├── docker-compose.yml       # Local development compose
└── .github/
    └── workflows/
        ├── docker.yml       # Docker Hub publishing
        └── lint.yml         # Code quality checks
```

### Environment Variables
- Loaded from root `.env` file (not committed)
- Template provided in `.env.example`
- Used by `docker-compose.yml` and scripts
- Notebooks load variables with `python-dotenv`

### Docker Hub Publishing
Configure in `.env`:
```env
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=your-access-token
DOCKER_REPOSITORY=maxlab
DOCKER_TAG=dev
```

**Local push**: `./scripts/docker-push.ps1` creates `latest` + `DOCKER_TAG`  
**CI push**: Push Git tag to trigger automatic publish

