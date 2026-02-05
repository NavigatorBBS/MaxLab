## Plan: Add start.ps1 Jupyter launcher

We’ll add a root-level start.ps1 that activates the `maxlab` conda environment and launches JupyterLab with the notebook root set to the workspace folder. Then we’ll update [README.md](README.md) to reference start.ps1 as the preferred launch method.

### Steps 3
1. Review current launch guidance in [README.md](README.md) for default workspace usage.
2. Create start.ps1 at the repo root to activate `maxlab` and run `jupyter lab --notebook-dir workspace`.
3. Update [README.md](README.md) to mention start.ps1 in the launch section.

### Further Considerations
1. None.
