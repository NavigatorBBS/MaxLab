# 🤖 MaxLab - JupyterLab Environment

[![Linting](https://github.com/NavigatorBBS/maxlab/workflows/Linting/badge.svg)](https://github.com/NavigatorBBS/maxlab/actions/workflows/lint.yml)
[![Docker Build and Push](https://github.com/NavigatorBBS/maxlab/workflows/Docker%20Build%20and%20Push/badge.svg)](https://github.com/NavigatorBBS/maxlab/actions/workflows/docker.yml)

**MaxLab** is a Python data science environment based on JupyterLab

**Features:**
- 📓 **Pre-configured JupyterLab** - Ready-to-use data science environment with pandas, numpy, matplotlib, and more
- 🐳 **Docker-based** - Consistent environment across all platforms
- 🎨 **Custom MaxLab Themes** - Includes NavigatorBBS-inspired light and dark JupyterLab themes plus MaxLab sidebar branding
- 🔧 **Git & GitHub CLI** - `git` and `gh` preinstalled system-wide for version control from container terminals
- 🧹 **Automatic Output Cleaning** - Pre-commit hooks keep your repository clean
- 🔧 **Easy Publishing** - Built-in scripts to push images to Docker Hub

---

## 🚀 Quick Start

### Start MaxLab with Docker Compose

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

---

## ⚙️ Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```powershell
Copy-Item .env.example .env
```

Edit `.env` for your setup:

```env
JUPYTER_PORT=8888                  # Port to expose JupyterLab
JUPYTER_NOTEBOOK_DIR=workspace     # Notebooks directory
DATA_DIR=workspace/data            # Data directory
API_KEY=your_api_key_here          # Example secret
```

Load variables in a notebook:

```python
from dotenv import load_dotenv
load_dotenv()
```

### Docker Configuration

The container respects these environment variables (set in `.env` or `docker-compose.yml`):

| Variable | Default | Description |
|----------|---------|-------------|
| `JUPYTER_PORT` | `8888` | Port to expose JupyterLab |
| `DOCKERHUB_USERNAME` | `local` | Docker namespace/user |
| `DOCKER_REPOSITORY` | `maxlab` | Docker repository name |
| `DOCKER_TAG` | `latest` | Docker image tag |

Security note: keep `.env` local and never commit real tokens.

---

## 🎨 MaxLab JupyterLab Themes

The Docker image now includes two MaxLab themes implemented as bundled JupyterLab extensions:

- `MaxLab Navigator Dark`
- `MaxLab Navigator Light`

Both themes keep native JupyterLab layout and behavior while applying a NavigatorBBS-inspired palette with subtle teal/green accents.

The image also includes a small branding extension that places `maxlab_logo.png` above the file browser launcher controls in the left sidebar.

MaxLab starts with `MaxLab Navigator Dark` by default on first launch.

### Switching Themes

1. Start MaxLab with Docker Compose.
2. Open JupyterLab.
3. Go to `Settings` -> `Theme`.
4. Choose `MaxLab Navigator Dark` or `MaxLab Navigator Light`.

### Theme Package Source

The bundled Python package lives at `packages/maxlab_navigator_theme`.

Frontend sources are split into three JupyterLab prebuilt extensions:

- `js/maxlab-navigator-dark`
- `js/maxlab-navigator-light`
- `js/maxlab-branding`

To rebuild the extension assets locally:

```powershell
npm install --prefix .\packages\maxlab_navigator_theme\js\maxlab-navigator-light
npm install --prefix .\packages\maxlab_navigator_theme\js\maxlab-navigator-dark
npm install --prefix .\packages\maxlab_navigator_theme\js\maxlab-branding

npm run build:prod --prefix .\packages\maxlab_navigator_theme\js\maxlab-navigator-light
npm run build:prod --prefix .\packages\maxlab_navigator_theme\js\maxlab-navigator-dark
npm run build:prod --prefix .\packages\maxlab_navigator_theme\js\maxlab-branding
```

To rebuild the Python distribution:

```powershell
python -m build .\packages\maxlab_navigator_theme
```

---

## 🐳 Docker Hub Publishing

### Configure Docker Hub Credentials

Add to `.env`:

```env
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=your-access-token
DOCKER_REPOSITORY=maxlab
DOCKER_TAG=dev
```

### Push Image to Docker Hub

```powershell
./scripts/docker-push.ps1
```

This builds and pushes both `latest` and your custom `DOCKER_TAG`.

### CI/CD Publishing

The GitHub Actions workflow automatically builds and pushes to Docker Hub when you push a Git tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Configure these secrets in your GitHub repository:
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

---

## 📦 Runtime Package Installation

Install packages at runtime within a notebook:

```python
%pip install package-name
```

---