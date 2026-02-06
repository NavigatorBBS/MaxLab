# Plan: Pre-commit Hook to Clear Jupyter Notebook Outputs

Install and configure the `pre-commit` framework with `nbstripout` to automatically strip all outputs from Jupyter notebooks before committing. When a notebook with outputs is committed, the hook will clear the outputs, stage the cleaned file, and proceed with the commit. This keeps your git history clean and prevents accidentally committing large outputs or sensitive data. Uses the widely-adopted pre-commit framework for reliability and maintainability.

## Steps

1. Update [setup.ps1](setup.ps1) to install `pre-commit` and `nbstripout` packages in the conda environment (add to the existing package installation list after `python-dotenv`)

2. Create [.pre-commit-config.yaml](.pre-commit-config.yaml) in the workspace root with:
   - Repo: `https://github.com/kynan/nbstripout`
   - Hook: `nbstripout` configured to clear all outputs (execution counts, stdout, stderr, images)
   - Files pattern: `^workspace/notebooks/.*\.ipynb$`

3. Update [README.md](README.md) to document the pre-commit setup:
   - Add section explaining that notebook outputs are automatically cleared
   - Include one-time installation command: `pre-commit install`
   - Note that developers should run this after initial setup

4. Create a one-time migration script or instructions to:
   - Run `pre-commit install` to activate the hook in `.git/hooks/pre-commit`
   - Optionally run `pre-commit run --all-files` to clean existing notebooks (will clear [welcome.ipynb](workspace/notebooks/welcome.ipynb) outputs)

5. Optionally add pre-commit configuration to [.github/workflows/lint.yml](.github/workflows/lint.yml) to verify notebooks have no outputs in CI

## Verification

1. Run `conda activate maxlab` and `pre-commit install`
2. Make a change to any notebook and execute a cell to generate output
3. Run `git add` and `git commit` - verify the hook strips outputs automatically
4. Check that the committed `.ipynb` file has `"outputs": []` for all cells
5. Test that non-notebook files commit normally without interference

## Decisions

- Chose pre-commit framework over simple bash script for robustness and ecosystem compatibility
- Configured to clear all outputs (not just images) to minimize repository size and exposure
- Auto-clear with staging (not blocking) for smoother developer workflow
