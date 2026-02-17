# MaxLab GitHub Actions Deployment Guide

## Prerequisites

⚠️ **Before deploying**, ensure your Windows server runner is fully configured.

Follow the [Deployment Checklist](DEPLOYMENT_CHECKLIST.md) to:
- Install required software (Git, Conda, **Tailscale**)
- Run `setup.ps1` to create maxlab environment
- Configure Tailscale auth secrets

**Quick check**:
```powershell
.\scripts\validate-deployment-ready.ps1
```

The validation script automatically finds conda in standard locations and checks all requirements. All checks must pass before attempting deployment.

---

## Overview

MaxLab supports **dual-environment deployment**:
- **Production** - Deployed from `main` branch to `D:\apps\MaxLab`
- **Test** - Deployed from `test` branch to `D:\apps\MaxLabTest`

Both deployments run on the same self-hosted Windows server runner and can execute in parallel without conflict.

## Quick Start

### Automatic Deployment (Push to Branch)

**Production Deployment:**
```bash
git push origin main
```
This automatically triggers deployment to `D:\apps\MaxLab`

**Test Deployment:**
```bash
git push origin test
```
This automatically triggers deployment to `D:\apps\MaxLabTest`

### Manual Deployment (Workflow Dispatch)

1. **Go to GitHub Repository**
   - Navigate to your MaxLab repository
   - Click the "Actions" tab

2. **Select Deploy Workflow**
   - Look for "Deploy MaxLab" in the list
   - Click on it

3. **Trigger the Workflow**
   - Click "Run workflow" button
   - Select branch to deploy: `main` (production) or `test` (test)
   - Click the green "Run workflow" button

4. **Monitor Deployment**
   - Watch the workflow run in real-time
   - See validation jobs (Python linting, Notebook checks) run in parallel on Ubuntu
   - See deployment job run on your Windows server runner
   - Check the deployment summary for confirmation

## Workflow Steps Explained

### Validation Phase (Runs in Parallel on Ubuntu)
```
Python Linting
  ↓ Checks all Python files with flake8
  ↓ Validates code style compliance

Notebook Outputs
  ↓ Checks notebooks with nbstripout
  ↓ Ensures notebooks have no saved outputs
```

These jobs run **once** regardless of which branch is deployed. Both deployment jobs wait for these to complete.

### Deployment Phase (Production - Main Branch)
```
1. Checkout code from GitHub (main branch)
2. Validate D:\apps\MaxLab directory
3. Clone or pull latest code
4. Verify critical files exist
5. Generate deployment summary
6. Setup MaxLabJupyterLab scheduled tasks
   (Uses native Windows Task Scheduler)
```

Runs automatically on: `git push origin main` or manual workflow dispatch with branch=main

### Deployment Phase (Test - Test Branch)
```
1. Checkout code from GitHub (test branch)
2. Validate D:\apps\MaxLabTest directory
3. Clone or pull latest code
4. Verify critical files exist
5. Generate deployment summary
6. Setup MaxLabJupyterLabTest scheduled tasks
   (Uses native Windows Task Scheduler)
```

Runs automatically on: `git push origin test` or manual workflow dispatch with branch=test

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

When using manual workflow dispatch, you can specify:

### Branch (Optional)
- **Options**: `main` (production), `test` (test)
- **Default**: `main`
- **Use case**: Deploy a different branch if using workflow dispatch
- **Example**: Set to `test` to manually trigger test deployment

## Environment Mapping

| Branch | Deploy Path | Service Name | Tailnet | Trigger |
|--------|-------------|--------------|---------|---------|
| `main` | `D:\apps\MaxLab` | `MaxLabJupyterLab` | `maxlab.cobbler-python.ts.net` | Push + Manual |
| `test` | `D:\apps\MaxLabTest` | `MaxLabJupyterLabTest` | `maxlab-test.cobbler-python.ts.net` | Push + Manual |

## After Deployment

The deployment workflow automatically sets up JupyterLab as a Windows service using NSSM.

### Service Status

Check which services are running:

**Production Service:**
```powershell
Get-Service MaxLabJupyterLab
```

**Test Service:**
```powershell
Get-Service MaxLabJupyterLabTest
```

Both tasks can run simultaneously on the same server. See the [SCHEDULED_TASK_SETUP.md](SCHEDULED_TASK_SETUP.md) guide for detailed task management.

### First-Time Setup (if needed)

**For Production:**
```powershell
cd D:\apps\MaxLab
./setup.ps1
```

**For Test:**
```powershell
cd D:\apps\MaxLabTest
./setup.ps1
```

### Manual Operations (optional)

**Manage Production Service:**
```powershell
Get-Service MaxLabJupyterLab           # Check status
Stop-Service MaxLabJupyterLab          # Stop
Start-Service MaxLabJupyterLab         # Start
Restart-Service MaxLabJupyterLab       # Restart
```

**Manage Test Service:**
```powershell
Get-Service MaxLabJupyterLabTest       # Check status
Stop-Service MaxLabJupyterLabTest      # Stop
Start-Service MaxLabJupyterLabTest     # Start
Restart-Service MaxLabJupyterLabTest   # Restart
```

For complete task management and troubleshooting, see [SCHEDULED_TASK_SETUP.md](SCHEDULED_TASK_SETUP.md).

## Workflow Features

✅ **Dual-Environment Deployment** - Separate production and test environments
✅ **Automatic Triggers** - Deploy on push to main/test, plus manual trigger available
✅ **Parallel Validation** - All lint checks run simultaneously (faster feedback)
✅ **Blocking Errors** - Deployment blocked if any validation fails
✅ **Smart Git** - Auto-clones or updates existing deployment
✅ **Verification** - Checks critical files exist after deployment
✅ **Clear Summary** - Displays commit info, timestamp, and next steps
✅ **Concurrent Deployments** - Both environments can deploy in parallel
✅ **Environment Tracking** - GitHub tracks both production and test deployments

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
   - Python linting runs first
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

4. **Separate services prevent conflicts**
   - Production: `MaxLabJupyterLab` in `D:\apps\MaxLab`
   - Test: `MaxLabJupyterLabTest` in `D:\apps\MaxLabTest`
   - Both can run simultaneously

## Advanced Usage

### Rollback to Previous Version

**For Production:**
```powershell
cd D:\apps\MaxLab
git log --oneline -n 10  # See recent commits
git checkout <commit-hash>  # Go back to specific commit
Restart-Service MaxLabJupyterLab
```

**For Test:**
```powershell
cd D:\apps\MaxLabTest
git log --oneline -n 10  # See recent commits
git checkout <commit-hash>  # Go back to specific commit
Restart-Service MaxLabJupyterLabTest
```

### Redeploy Same Commit
1. Run workflow again with same branch
2. Will pull latest and verify on target environment

### Concurrent Deployments
Both environments support parallel deployments:
- Push to `main` and `test` in quick succession
- Both will deploy to their respective directories
- No conflicts due to separate directories and service names

## Support

If you encounter issues:
1. Check workflow logs in GitHub Actions
2. Look for specific error messages
3. Verify Windows server has internet
4. Verify GitHub Actions runner is online
5. Check file permissions on both deployment directories:
   - `D:\apps\MaxLab` (production)
   - `D:\apps\MaxLabTest` (test)

## Troubleshooting Dual Deployments

### Both Deployments Failing
- Check if validation jobs (Python lint, Notebook outputs) are failing
- If validation fails, both deployments are blocked
- Fix the issue and push again

### One Deployment Fails, Other Succeeds
- Each branch deployment is independent
- Production failure doesn't affect test deployment
- Fix the issue on the specific branch and re-push

### Services Won't Start
- Check logs in respective directories:
  - Production: `D:\apps\MaxLab\logs\service\`
  - Test: `D:\apps\MaxLabTest\logs\service\`
- Ensure conda environment `maxlab` is installed
- Check port conflicts (use different JUPYTER_PORT per .env)

## Files Modified/Created

- ✅ Updated: `.github/workflows/deploy.yml` - Parameterized for dual-environment deployment
- ✅ Updated: `DEPLOYMENT_GUIDE.md` - This file
- ✅ Updated: `SCHEDULED_TASK_SETUP.md` - Task management documentation
- ✅ No changes needed to existing code
- ✅ No changes needed to setup.ps1 or start.ps1
