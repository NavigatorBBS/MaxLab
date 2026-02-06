# Pre-commit Hook Setup Guide

This guide explains how to set up the pre-commit hook for clearing Jupyter notebook outputs.

## Why Pre-commit Hooks?

The pre-commit hook automatically strips outputs from Jupyter notebooks before you commit. This keeps your git history clean by preventing:
- Large output data (plots, tables, etc.) from bloating the repository
- Accidental commit of sensitive data from notebook execution
- Confusing diffs that show notebook execution counts changing without code changes

## Initial Setup (One-Time)

After cloning the repository and running `setup.ps1`, activate the pre-commit hook:

```powershell
conda activate maxlab
pre-commit install
```

This creates a `.git/hooks/pre-commit` script that runs automatically before each commit.

**That's it!** You're now protected.

## How to Use

### Normal workflow (no changes needed)

1. Edit and run notebooks as usual
2. Stage your changes: `git add workspace/notebooks/my-notebook.ipynb`
3. Commit: `git commit -m "Update notebook"`
4. ✅ The hook automatically strips outputs and proceeds with the commit

You don't need to manually clean notebooks—it happens automatically.

### Manual cleanup

If you want to manually strip outputs from notebooks without committing:

```powershell
# Clean all notebooks
pre-commit run --all-files

# Clean a specific notebook
nbstripout workspace/notebooks/my-notebook.ipynb
```

## Troubleshooting

### "pre-commit command not found"

Ensure you've activated the conda environment:

```powershell
conda activate maxlab
```

Then try again:

```powershell
pre-commit install
```

### "Hook failed and modified files"

Pre-commit may strip outputs and stage the changes. Review the changes:

```powershell
git diff --cached
git status
```

If the changes look correct (only outputs removed), proceed with commit:

```powershell
git commit -m "Your message"
```

### Reinstalling the hook

If you need to reinstall the hook (e.g., after cloning):

```powershell
conda activate maxlab
pre-commit install
```

## Configuration

The hook configuration is in [`.pre-commit-config.yaml`](.pre-commit-config.yaml):

- **Tool:** nbstripout v0.7.1
- **Files:** `workspace/notebooks/*.ipynb`
- **Action:** Strips all outputs, execution counts, and metadata
- **Behavior:** Automatic, non-blocking

## CI/CD Integration

The [`.github/workflows/lint.yml`](lint.yml) workflow includes a `notebook-outputs` job that verifies notebooks have no outputs on every push and pull request. All notebooks must pass this check to merge code.

If CI fails because of notebook outputs:

1. Run `pre-commit run --all-files` locally
2. Commit the cleaned notebooks
3. Push again

## Questions?

See the [README.md](../../README.md#-git-pre-commit-hooks) for more information.
