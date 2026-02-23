## Plan: Docker Hub Build/Push Unification (DRAFT)

We’ll standardize local + CI around split Docker variables so you can build and push predictable tags to Docker Hub from both PowerShell scripts and GitHub Actions. Based on your choices, the model will be: Docker Hub namespace/repo from separate vars, with local push producing `latest` plus one custom tag from `.env`. This plan updates scripts, docs, and workflow alignment, while keeping Docker runtime behavior intact unless a Dockerfile change is truly required.

**Steps**
1. Define and document canonical env model in [.env.example](.env.example), [README.md](README.md), and [QUICK_REFERENCE.md](QUICK_REFERENCE.md): `DOCKERHUB_USERNAME`, `DOCKER_REPOSITORY`, `DOCKER_TAG`, plus derived image ref semantics.
2. Refactor local build logic in [scripts/docker-build.ps1](scripts/docker-build.ps1) to compose image refs from split vars and build with deterministic tags (`latest` and custom tag), replacing current single-string `DOCKER_IMAGE_NAME` dependency.
3. Refactor local push flow in [scripts/docker-push.ps1](scripts/docker-push.ps1) to push both tags, validate required vars early, and keep secure login/logout flow with `DOCKERHUB_TOKEN`.
4. Align local run behavior in [scripts/docker-run.ps1](scripts/docker-run.ps1) and [docker-compose.yml](docker-compose.yml) so compose uses the same derived image naming convention (or explicit override var) without reintroducing old `DOCKER_IMAGE_NAME` ambiguity.
5. Update shared helper usage in [scripts/common.ps1](scripts/common.ps1) where appropriate to avoid duplicated env/repo-root logic and keep script conventions consistent.
6. Align CI variable naming and tag behavior in [.github/workflows/docker.yml](.github/workflows/docker.yml) so Docker Hub image naming matches local conventions while preserving CI metadata tags as needed.
7. Review [Dockerfile](Dockerfile) only for compatibility touchpoints (no functional change unless variable/tag assumptions require it), ensuring no regression in port/notebook runtime defaults.

**Verification**
- Env sanity: confirm required vars exist and parse correctly via script preflight messages.
- Local build: run `./scripts/docker-build.ps1`, then verify both tags exist with `docker image ls`.
- Local push: run `./scripts/docker-push.ps1`, then `docker pull <username>/<repo>:latest` and `docker pull <username>/<repo>:<custom-tag>`.
- Compose/run: run `docker compose config` and `./scripts/docker-run.ps1` to verify resolved image and startup.
- CI alignment: trigger Docker workflow in [.github/workflows/docker.yml](.github/workflows/docker.yml) and confirm expected tags in Docker Hub.

**Decisions**
- Chosen image model: split vars (`DOCKERHUB_USERNAME` + repository + tag).
- Chosen local tag strategy: push `latest` + custom `.env` tag.
- Chosen scope: include scripts, docs, workflow, and Dockerfile only if needed for compatibility.
