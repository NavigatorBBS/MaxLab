## Plan: Insert sysop pip install in Docker build (DRAFT)

Add one focused change in [Dockerfile](Dockerfile#L1-L52) so the VCS pip dependency is installed inside the conda environment named by CONDA_ENV, exactly between the existing conda package install block and the ipykernel registration block. Because your dependency uses a git+https source, include a system git install in the image build to avoid pip VCS failures. Keep this as a hardcoded one-off install (per your choice), with no new ARG plumbing.

**Steps**
1. Add a system dependency step in [Dockerfile](Dockerfile#L14-L24) to install git before Python package installation begins.
2. Keep the current conda environment creation and conda package install flow in [Dockerfile](Dockerfile#L21-L37) unchanged.
3. Insert a new RUN step in [Dockerfile](Dockerfile#L37-L43), after the conda install block and before kernel registration, using conda run -n ${CONDA_ENV} python -m pip install git+https://github.com/NavigatorBBS/sysop.git@v0.1.0.
4. Preserve the existing kernel registration order in [Dockerfile](Dockerfile#L39-L43) so the registered kernel reflects the fully built environment.
5. Keep the change scoped to [Dockerfile](Dockerfile), with no edits to compose/scripts unless verification reveals a command mismatch.

**Verification**
- Run: docker compose build --no-cache maxlab
- Run: docker compose run --rm maxlab conda run -n maxlab python -m pip freeze
- Confirm freeze output includes sysop @ git+https://github.com/NavigatorBBS/sysop.git@v0.1.0
- Optional runtime check: docker compose up -d, then open Jupyter and verify the maxlab kernel starts normally

**Decisions**
- Hardcoded install in [Dockerfile](Dockerfile), not build ARG.
- Include system git install for git+https reliability.
- Use conda run -n ${CONDA_ENV} python -m pip install to guarantee install target is the intended conda env.
