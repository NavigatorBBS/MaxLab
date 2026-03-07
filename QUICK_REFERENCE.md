# Quick Reference: MaxLab Docker

## 🚀 Quick Start

```bash
# Start MaxLab
docker compose up

# Run in background
docker compose up -d

# Stop
docker compose down
```

Access JupyterLab at `http://localhost:8888`

---

## 🐳 Docker Hub Publishing

### Local Build & Push

Configure `.env`:

```env
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=your-access-token
DOCKER_REPOSITORY=maxlab
DOCKER_TAG=dev
```

Build and push:

```powershell
# Build locally
./scripts/docker-build.ps1

# Push to Docker Hub
./scripts/docker-push.ps1
```

### CI/CD Publishing

Push a Git tag to trigger automatic Docker Hub publish:

```bash
git tag v1.0.0
git push origin v1.0.0
```

**GitHub Secrets Required:**
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

### Tags Created

**Local push:** Creates `latest` + `DOCKER_TAG` from `.env`  
**CI push:** Creates Git tag + SHA + `latest` (main branch only)

---

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `JUPYTER_PORT` | `8888` | JupyterLab port |
| `DOCKERHUB_USERNAME` | `local` | Docker namespace |
| `DOCKER_REPOSITORY` | `maxlab` | Repository name |
| `DOCKER_TAG` | `latest` | Image tag |

### PowerShell Scripts

| Script | Purpose |
|--------|---------|
| `docker-build.ps1` | Build image locally |
| `docker-push.ps1` | Build and push to Docker Hub |
| `docker-run.ps1` | Start with docker compose |

---

## 📦 Workspace

- `workspace/notebooks/` - Jupyter notebooks
- Mounted as volume - changes persist on host
- Pre-commit hooks strip outputs before git commit
- Image includes `sysop` in the `maxlab` conda environment (build-time install from `git+https://github.com/NavigatorBBS/sysop.git@v0.1.0`)

---

## 🔗 Useful Links

- Docker workflow: `.github/workflows/docker.yml`
- Compose config: `docker-compose.yml`
- Dockerfile: `Dockerfile`
- Sysop project usage: `https://github.com/NavigatorBBS/sysop`

---

**Last Updated**: 2026-03-06
