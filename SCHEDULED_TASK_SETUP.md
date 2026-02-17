# MaxLab Scheduled Task Setup Guide

## Overview

MaxLab runs JupyterLab using **Windows Task Scheduler** with native PowerShell scripts. This provides:
- ✅ No third-party dependencies (native Windows feature)
- ✅ Automatic startup on server reboot
- ✅ Auto-restart if JupyterLab crashes (via watchdog)
- ✅ Reliable task creation and deletion
- ✅ Support for multiple tasks (production + test) on same server

## Tasks

MaxLab creates two scheduled tasks per deployment:

| Task | Purpose | Schedule |
|------|---------|----------|
| `MaxLabJupyterLab-Startup` | Starts JupyterLab | At system startup (30s delay) |
| `MaxLabJupyterLab-Watchdog` | Monitors and restarts if crashed | Every 5 minutes |

### Production Tasks

| Task Name | Directory | Port |
|-----------|-----------|------|
| `MaxLabJupyterLab-Startup` | `D:\apps\MaxLab` | 8888 |
| `MaxLabJupyterLab-Watchdog` | `D:\apps\MaxLab` | 8888 |

### Test Tasks

| Task Name | Directory | Port |
|-----------|-----------|------|
| `MaxLabJupyterLabTest-Startup` | `D:\apps\MaxLabTest` | 8889 |
| `MaxLabJupyterLabTest-Watchdog` | `D:\apps\MaxLabTest` | 8889 |

Both sets of tasks can run simultaneously on the same Windows server.

## Automatic Setup via Deployment

When you run the GitHub Actions deployment workflow, the tasks are automatically:
1. **Removed** if they already exist (clean slate)
2. **Created** with proper triggers and settings
3. **Started** and verified

No manual commands needed—the workflow handles everything!

## Task Details

### Startup Task

| Property | Value |
|----------|-------|
| **Trigger** | At system startup (30 second delay) |
| **Run As** | NT AUTHORITY\SYSTEM |
| **Action** | Runs `start.ps1` in deployment directory |
| **Restart on Failure** | Yes (up to 3 times, 1 minute interval) |

### Watchdog Task

| Property | Value |
|----------|-------|
| **Trigger** | Every 5 minutes |
| **Run As** | NT AUTHORITY\SYSTEM |
| **Action** | Checks if JupyterLab is running, restarts if not |
| **Execution Time Limit** | 5 minutes |

## Important: Port Configuration

To run both production and test simultaneously, they must use different ports:

**Production `.env` (D:\apps\MaxLab\.env):**
```
JUPYTER_PORT=8888
```

**Test `.env` (D:\apps\MaxLabTest\.env):**
```
JUPYTER_PORT=8889
```

## Managing Tasks

### Check Task Status

**Production:**
```powershell
# View task info
Get-ScheduledTask -TaskName "MaxLabJupyterLab-Startup"
Get-ScheduledTaskInfo -TaskName "MaxLabJupyterLab-Startup"

# View watchdog info
Get-ScheduledTask -TaskName "MaxLabJupyterLab-Watchdog"
```

**Test:**
```powershell
Get-ScheduledTask -TaskName "MaxLabJupyterLabTest-Startup"
Get-ScheduledTask -TaskName "MaxLabJupyterLabTest-Watchdog"
```

### Start Task Manually

**Production:**
```powershell
Start-ScheduledTask -TaskName "MaxLabJupyterLab-Startup"
```

**Test:**
```powershell
Start-ScheduledTask -TaskName "MaxLabJupyterLabTest-Startup"
```

### Stop Task

**Production:**
```powershell
Stop-ScheduledTask -TaskName "MaxLabJupyterLab-Startup"
```

**Test:**
```powershell
Stop-ScheduledTask -TaskName "MaxLabJupyterLabTest-Startup"
```

### Disable/Enable Tasks

```powershell
# Disable (prevents running)
Disable-ScheduledTask -TaskName "MaxLabJupyterLab-Startup"
Disable-ScheduledTask -TaskName "MaxLabJupyterLab-Watchdog"

# Enable
Enable-ScheduledTask -TaskName "MaxLabJupyterLab-Startup"
Enable-ScheduledTask -TaskName "MaxLabJupyterLab-Watchdog"
```

### Remove Tasks Completely

```powershell
# Stop first
Stop-ScheduledTask -TaskName "MaxLabJupyterLab-Startup" -ErrorAction SilentlyContinue
Stop-ScheduledTask -TaskName "MaxLabJupyterLab-Watchdog" -ErrorAction SilentlyContinue

# Remove
Unregister-ScheduledTask -TaskName "MaxLabJupyterLab-Startup" -Confirm:$false
Unregister-ScheduledTask -TaskName "MaxLabJupyterLab-Watchdog" -Confirm:$false
```

## Viewing Logs

### JupyterLab Logs

**Production:**
```powershell
Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stdout.log" -Tail 50
```

**Test:**
```powershell
Get-Content "D:\apps\MaxLabTest\logs\service\jupyterlab-stdout.log" -Tail 50
```

### Watchdog Logs

**Production:**
```powershell
Get-Content "D:\apps\MaxLab\logs\service\watchdog.log" -Tail 50
```

**Test:**
```powershell
Get-Content "D:\apps\MaxLabTest\logs\service\watchdog.log" -Tail 50
```

### Follow Logs in Real-Time

```powershell
Get-Content "D:\apps\MaxLab\logs\service\watchdog.log" -Tail 1 -Wait
```

## Troubleshooting

### Task Won't Start

**Symptom**: Task shows "Ready" but won't run

**Steps to diagnose:**
1. Check task last result:
   ```powershell
   Get-ScheduledTaskInfo -TaskName "MaxLabJupyterLab-Startup"
   ```

2. Common result codes:
   - `0` = Success
   - `267009` = Task is currently running
   - `267011` = Task has not run yet
   - `2147942401` = Access denied (permissions issue)

3. Verify start.ps1 exists:
   ```powershell
   Test-Path "D:\apps\MaxLab\start.ps1"
   ```

4. Test running manually:
   ```powershell
   cd D:\apps\MaxLab
   ./start.ps1
   ```

### JupyterLab Keeps Restarting

**Symptom**: Watchdog log shows constant restarts

**Check:**
1. View error logs:
   ```powershell
   Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stderr.log" -Tail 100
   ```

2. Check if port is in use:
   ```powershell
   netstat -ano | findstr :8888
   ```

3. Verify conda environment:
   ```powershell
   conda env list
   ```

### Port Already in Use

**Symptom**: JupyterLab fails to start, port conflict

**Solution:**
```powershell
# Find what's using the port
netstat -ano | findstr :8888

# Check .env files have different ports
Get-Content "D:\apps\MaxLab\.env"
Get-Content "D:\apps\MaxLabTest\.env"
```

### Can't Connect to JupyterLab

**Check:**
1. Task is running:
   ```powershell
   Get-ScheduledTask -TaskName "MaxLabJupyterLab-Startup" | Select State
   ```

2. Port is listening:
   ```powershell
   netstat -ano | findstr LISTENING | findstr :8888
   ```

3. Firewall allows port:
   - Open Windows Defender Firewall
   - Check inbound rules for port 8888

## Tailscale HTTPS Setup

See [Tailscale documentation](https://tailscale.com/kb/) for secure access via:
```
https://maxlab.cobbler-python.ts.net
```

## Using Task Scheduler GUI

You can also manage tasks via the Windows Task Scheduler GUI:

1. Open **Task Scheduler** (`taskschd.msc`)
2. Navigate to **Task Scheduler Library**
3. Find tasks starting with `MaxLabJupyterLab`
4. Right-click to Run, Stop, Disable, or view Properties

## Deployment Workflow Integration

The GitHub Actions deployment workflow automatically:

1. **Removes** existing startup and watchdog tasks
2. **Creates** new tasks with current configuration
3. **Starts** both tasks
4. **Verifies** JupyterLab is running

This happens in the "Setup Scheduled Task for JupyterLab" step of the workflow.

## Related Documentation

- [MaxLab Deployment Guide](DEPLOYMENT_GUIDE.md) - Overall deployment process
- [MaxLab README](README.md) - Project overview
- [Tailscale Documentation](https://tailscale.com/kb/) - Tailscale setup

## Quick Reference Commands

```powershell
# Task management
Get-ScheduledTask -TaskName "MaxLabJupyterLab*"     # List tasks
Start-ScheduledTask -TaskName "MaxLabJupyterLab-Startup"   # Start
Stop-ScheduledTask -TaskName "MaxLabJupyterLab-Startup"    # Stop

# Logs
Get-Content D:\apps\MaxLab\logs\service\watchdog.log -Tail 50

# Port checking
netstat -ano | findstr :8888
```

## Support

For issues:
1. Check watchdog logs: `D:\apps\MaxLab\logs\service\watchdog.log`
2. Check JupyterLab logs: `D:\apps\MaxLab\logs\service\`
3. Test manually: `cd D:\apps\MaxLab && ./start.ps1`
4. Check GitHub Actions workflow logs for deployment issues
