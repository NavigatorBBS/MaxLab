## Plan: Modular Setup + .env Loading

Refactor setup into per-feature scripts so you can run steps independently while keeping an end-to-end path. Keep setup.ps1 as an orchestrator entry point for backwards compatibility, but split each feature into its own script and align behavior with README guidance. Add automatic .env creation from .env.example and load it in start.ps1 to drive defaults like port and notebook dir. Expand setup to install Conda base, pip extras (including semantic-kernel), pre-commit, and nbstripout so the documented setup is fully automated and consistent with pyproject.toml.

**Steps**
1. Audit current setup flow in [setup.ps1](setup.ps1), startup behavior in [start.ps1](start.ps1), and documented expectations in [README.md](README.md), [.env.example](.env.example), [pyproject.toml](pyproject.toml), and [.pre-commit-config.yaml](.pre-commit-config.yaml) to confirm the exact steps to extract and automate.
2. Create a feature-script layout (new folder, e.g., [scripts](scripts)) with one script per step: Conda bootstrapping or detection, env creation, Conda package install, pip install of project + extras, Jupyter kernel registration, pre-commit setup, nbstripout setup, and .env creation from template.
3. Update [setup.ps1](setup.ps1) to call each feature script in sequence and allow running individual steps directly; ensure steps are idempotent and provide clear output about what was done or skipped.
4. Implement .env handling: if missing, copy from [.env.example](.env.example) into .env; load it in [start.ps1](start.ps1) and apply precedence command-line args > .env > defaults; keep behavior compatible with existing -Port and workspace default.
5. Align documentation in [README.md](README.md) to reflect the new modular scripts, updated behavior, and how to run individual steps.

**Verification**
- Manual checks: run the full setup path, then run each feature script independently to confirm idempotency and clear messaging.
- Manual checks: start Jupyter with and without .env to confirm defaults and overrides are applied correctly.
- Manual checks: verify pre-commit hooks installed and nbstripout config applied to notebooks.

**Decisions**
- Modularity: split into multiple scripts per feature and keep setup.ps1 as the orchestrator for end-to-end runs.
- Automation: include pip extras, pre-commit, and nbstripout in setup to match documented expectations.
- Config: auto-create .env from .env.example and load it during start.
