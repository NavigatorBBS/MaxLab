# MaxLab GitHub Actions Deployment Guide

## Quick Start

### How to Deploy

1. **Go to GitHub Repository**
   - Navigate to your MaxLab repository
   - Click the "Actions" tab

2. **Select Deploy Workflow**
   - Look for "Deploy MaxLab" in the list
   - Click on it

3. **Trigger the Workflow**
   - Click "Run workflow" button
   - (Optional) Select a custom branch in the dropdown
   - Click the green "Run workflow" button

4. **Monitor Deployment**
   - Watch the workflow run in real-time
   - See validation jobs (PowerShell, Python, Notebooks) run in parallel on Ubuntu
   - See deployment job run on your Windows server runner
   - Check the deployment summary for confirmation

## Workflow Steps Explained

### Validation Phase (Runs in Parallel on Ubuntu)
```
PowerShell Linting
  ↓ Checks all .ps1 files with PSScriptAnalyzer
  ↓ Validates no warnings or errors

Python Linting  
  ↓ Checks all Python files with flake8
  ↓ Validates code style compliance

Notebook Outputs
  ↓ Checks notebooks with nbstripout
  ↓ Ensures notebooks have no saved outputs
```

### Deployment Phase (Runs on Windows Server)
```
1. Checkout code from GitHub
2. Validate D:\apps\MaxLab directory
3. Clone or pull latest code
4. Verify critical files exist
5. Generate deployment summary
```

## Troubleshooting

### "Runner not found" or "self-hosted runner offline"
**Problem**: Windows server runner isn't available
**Solution**: 
- SSH into Windows server
- Verify GitHub Actions runner service is running
- Check runner is configured with `windows-server` label

### "Validation failed" (lint errors)
**Problem**: PowerShell, Python, or notebook validation failed
**Solution**:
- Check workflow logs for specific error
- Fix the issue in your code locally
- Test locally before pushing

### "Deployment failed" (git error)
**Problem**: Git pull/clone failed on Windows server
**Solution**:
- Check internet connectivity on server
- Verify git is installed: `git --version`
- Check repository URL is accessible

### "Deployment summary is empty"
**Problem**: Deployment completed but no info displayed
**Solution**:
- Check GitHub Actions summary panel
- Try running workflow again
- Check if D:\apps\MaxLab exists and has .git directory

## Deployment Inputs

When running the workflow, you can specify:

### Branch (Optional)
- **Default**: `main`
- **Can override**: Any branch in your repository
- **Use case**: Deploy a feature branch for testing
- **Example**: Set to `develop` to test staging branch

## After Deployment

Once deployment completes successfully, on your Windows server:

```powershell
cd D:\apps\MaxLab

# First time only: Run setup
./setup.ps1

# Start JupyterLab
./start.ps1
```

## Workflow Features

✅ **Parallel Validation** - All lint checks run simultaneously (faster feedback)
✅ **Blocking Errors** - Deployment blocked if any validation fails
✅ **Smart Git** - Auto-clones or updates existing deployment
✅ **Verification** - Checks critical files exist after deployment
✅ **Clear Summary** - Displays commit info, timestamp, and next steps
✅ **Branch Selection** - Deploy any branch, not just main
✅ **Environment Tracking** - GitHub tracks production deployments

## Monitoring

### View Workflow Status
- GitHub Actions tab → Deploy MaxLab → Latest run
- Green checkmark = Success
- Red X = Failed (check logs)
- Yellow circle = In progress

### View Deployment Details
- Click workflow run
- Scroll to "Create deployment summary" step
- See commit hash, branch, timestamp
- See suggested next steps

## Safety Features

1. **All changes validated before deployment**
   - PowerShell lint runs first
   - Python lint runs first
   - Notebook checks run first
   - Deployment only if ALL pass

2. **Critical files verified after deployment**
   - setup.ps1 must exist
   - start.ps1 must exist
   - scripts/common.ps1 must exist

3. **Clear error messages**
   - Know exactly what failed
   - Know how to fix it
   - Can retry after fixing

## Advanced Usage

### Rollback to Previous Version
```powershell
cd D:\apps\MaxLab
git log --oneline -n 10  # See recent commits
git checkout <commit-hash>  # Go back to specific commit
```

### Redeploy Same Commit
Run workflow again with same branch - will pull latest and verify

### Deploy Feature Branch
1. Run workflow
2. Select your feature branch in inputs
3. Code deploys from that branch for testing

## Support

If you encounter issues:
1. Check workflow logs in GitHub Actions
2. Look for specific error messages
3. Verify Windows server has internet
4. Verify GitHub Actions runner is online
5. Check file permissions on D:\apps\MaxLab

## Files Modified/Created

- ✅ Created: `.github/workflows/deploy.yml` - Main deployment workflow
- ✅ No changes needed to existing code
- ✅ No changes needed to setup.ps1 or start.ps1
