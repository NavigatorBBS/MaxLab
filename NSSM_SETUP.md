# MaxLab NSSM Service Setup Guide

## Overview

MaxLab now runs JupyterLab as a Windows service using **NSSM** (Non-Sucking Service Manager). This provides:
- ✅ Automatic startup on server reboot
- ✅ Auto-restart if JupyterLab crashes
- ✅ Centralized logging to files and Windows Event Viewer
- ✅ Easy service management without manual scripts

## Automatic Setup via Deployment

When you run the GitHub Actions deployment workflow, the service is automatically:
1. **Created** with the name `MaxLabJupyterLab`
2. **Configured** with proper logging and auto-restart
3. **Started** and verified as running

No manual NSSM commands needed—the workflow handles everything!

## Service Details

| Property | Value |
|----------|-------|
| **Service Name** | `MaxLabJupyterLab` |
| **Service Type** | Windows Service |
| **Auto Start** | Yes (starts on reboot) |
| **Auto Restart** | Yes (on crash) |
| **Restart Delay** | 5 seconds |
| **Log Location** | `D:\apps\MaxLab\logs\service\` |
| **Port** | 8888 (from `JUPYTER_PORT`) |
| **Environment** | `maxlab` conda environment |

## Managing the Service

### Check Service Status
```powershell
# Using Windows Services
Get-Service MaxLabJupyterLab

# Using NSSM (detailed)
nssm status MaxLabJupyterLab
```

**Output meanings:**
- `Running` = Service is active, JupyterLab is running
- `Stopped` = Service is not running
- `Paused` = Service is paused

### Start the Service
```powershell
# Using Windows Services
Start-Service MaxLabJupyterLab

# Or using NSSM
nssm start MaxLabJupyterLab
```

### Stop the Service
```powershell
# Using Windows Services
Stop-Service MaxLabJupyterLab -Force

# Or using NSSM
nssm stop MaxLabJupyterLab
```

### Restart the Service
```powershell
# Using Windows Services
Restart-Service MaxLabJupyterLab

# Or using NSSM
nssm restart MaxLabJupyterLab
```

## Viewing Logs

### View Recent Logs (Last 50 Lines)
```powershell
Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stdout.log" -Tail 50
```

### Follow Logs in Real-Time (Tail)
```powershell
# Using Get-Content with -Wait (Ctrl+C to stop)
Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stdout.log" -Tail 1 -Wait

# Or use PowerShell tail (if available)
tail -f "D:\apps\MaxLab\logs\service\jupyterlab-stdout.log"
```

### View Error Logs
```powershell
Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stderr.log" -Tail 50
```

### View Windows Event Viewer Logs
1. Open **Event Viewer** (`eventvwr.msc`)
2. Navigate to **Windows Logs** → **Application**
3. Filter for events with source `MaxLabJupyterLab`

## Log Rotation

Logs are automatically rotated when they reach 10 MB. Old logs are archived to prevent disk space issues.

Log files:
- `jupyterlab-stdout.log` - Standard output (normal operation)
- `jupyterlab-stderr.log` - Error output (problems)

## Troubleshooting

### Service Won't Start

**Symptom**: Service shows "Stopped" but won't start

**Steps to diagnose:**
1. Check the logs:
   ```powershell
   Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stderr.log" -Tail 100
   ```

2. Verify conda environment exists:
   ```powershell
   conda env list
   ```

3. Verify JupyterLab is installed:
   ```powershell
   conda activate maxlab
   jupyter --version
   ```

4. Test running JupyterLab manually:
   ```powershell
   cd D:\apps\MaxLab
   ./start.ps1
   ```

### Port Already in Use

**Symptom**: Logs show "Address already in use" for port 8888

**Solution 1 - Find and stop conflicting process:**
```powershell
netstat -ano | findstr :8888
taskkill /PID <PID> /F
```

**Solution 2 - Use different port:**
1. Edit `.env` file:
   ```
   JUPYTER_PORT=9000
   ```
2. Restart service:
   ```powershell
   Restart-Service MaxLabJupyterLab
   ```

### Service Keeps Crashing

**Symptom**: Service restarts repeatedly

**Diagnosis:**
1. Check logs for error messages
2. Verify all dependencies are installed:
   ```powershell
   conda activate maxlab
   pip list | grep jupyter
   ```
3. Check notebook directory exists:
   ```powershell
   Test-Path "D:\apps\MaxLab\workspace"
   ```

**Recovery:**
- Stop service
- Fix the underlying issue
- Restart service

### Can't Connect to JupyterLab

**Symptom**: Service is running but can't access JupyterLab

**Check:**
1. Service is running:
   ```powershell
   Get-Service MaxLabJupyterLab
   ```

2. Port is listening:
   ```powershell
   netstat -ano | findstr LISTENING | findstr :8888
   ```

3. Firewall allows port 8888:
   - Open Windows Defender Firewall
   - Check inbound rules for port 8888

4. Try accessing locally first:
   ```powershell
   curl http://localhost:8888
   ```

## Tailscale HTTPS Setup

To access JupyterLab securely via Tailscale at `https://maxlab.cobbler-python.ts.net:443`:

### Prerequisites
- Tailscale installed and running on Windows server
- Device connected to your Tailscale network
- Tailscale DNS enabled

### Setup Steps

#### 1. Configure Tailscale on Windows Server
```powershell
# Start Tailscale (if not running)
Start-Service Tailscale

# Verify connection
tailscale status

# Note your Tailscale IP (e.g., 100.x.x.x)
```

#### 2. Create HTTPS Reverse Proxy (Using IIS or Caddy)

**Option A: Using Caddy (Recommended)**

1. Download Caddy: https://caddyserver.com/download
2. Create `D:\apps\MaxLab\Caddyfile`:
   ```
   maxlab.cobbler-python.ts.net {
     reverse_proxy localhost:8888 {
       header_up X-Forwarded-For {http.request.remote.host}
       header_up X-Forwarded-Proto https
       header_up X-Real-IP {http.request.remote.host}
     }
   }
   ```
3. Start Caddy (as admin):
   ```powershell
   cd "C:\path\to\caddy"
   .\caddy.exe run --config "D:\apps\MaxLab\Caddyfile"
   ```

**Option B: Using IIS with Application Request Routing (ARR)**

1. Install IIS with Application Request Routing module
2. Create new website pointing to maxlab.cobbler-python.ts.net
3. Configure ARR to reverse proxy to localhost:8888
4. Configure HTTPS certificate (Tailscale provides SSL)

#### 3. Set Up Tailscale Funnel (Optional - Exposes outside Tailnet)

```powershell
# Enable HTTPS funnel on Tailscale IP
tailscale funnel 443

# This makes it accessible beyond your Tailnet
```

#### 4. Verify Access

From another device on your Tailnet:
```bash
# Test HTTP redirect
curl http://maxlab.cobbler-python.ts.net

# Access HTTPS
open https://maxlab.cobbler-python.ts.net
```

### Tailscale Troubleshooting

**Can't resolve maxlab.cobbler-python.ts.net:**
- Verify Tailscale MagicDNS is enabled
- Check `tailscale status` for device name
- Use Tailscale IP directly: `https://100.x.x.x`

**Certificate errors:**
- Caddy auto-generates certificates for .ts.net domains
- Ensure Caddy has internet access
- Check Caddy logs for cert issues

**Connection refused:**
- Verify reverse proxy (Caddy/IIS) is running
- Check JupyterLab is accessible on localhost:8888
- Verify firewall allows inbound 443

## Advanced Service Configuration

### View All NSSM Settings
```powershell
nssm dump MaxLabJupyterLab
```

### Edit Service Settings
```powershell
# Change auto-restart delay (in milliseconds)
nssm set MaxLabJupyterLab AppRestartDelay 10000

# Change restart throttle
nssm set MaxLabJupyterLab AppThrottle 2000

# Apply changes without restarting service
nssm restart MaxLabJupyterLab
```

### Remove Service Completely
```powershell
# Stop service first
Stop-Service MaxLabJupyterLab

# Remove via NSSM
nssm remove MaxLabJupyterLab confirm

# Verify removal
Get-Service MaxLabJupyterLab  # Should fail with "not found"
```

## Environment Variables in Service

The service loads environment variables from `.env` file in `D:\apps\MaxLab`:

**Key variables:**
```
JUPYTER_PORT=8888
JUPYTER_NOTEBOOK_DIR=workspace
```

**To modify service behavior:**
1. Edit `.env` file
2. Restart service:
   ```powershell
   Restart-Service MaxLabJupyterLab
   ```

## Performance Monitoring

### Memory Usage
```powershell
Get-Process | Where-Object {$_.ProcessName -like "*python*"}
```

### CPU Usage Over Time
```powershell
Get-Counter -Counter "\Process(python*)\% Processor Time" -SampleInterval 1 -MaxSamples 10
```

### Restart History
```powershell
Get-EventLog Application -Source "MaxLabJupyterLab" -Newest 20
```

## Deployment Workflow Integration

The GitHub Actions deployment workflow automatically:

1. **Stops** any existing `MaxLabJupyterLab` service
2. **Removes** the old service
3. **Creates** a new service with latest code
4. **Configures** logging and auto-restart
5. **Starts** the service
6. **Verifies** it's running

This happens in the "Setup NSSM JupyterLab Service" step of the workflow.

## Related Documentation

- [MaxLab Deployment Guide](DEPLOYMENT_GUIDE.md) - Overall deployment process
- [MaxLab README](README.md) - Project overview
- [NSSM Documentation](https://nssm.cc/usage) - Detailed NSSM reference
- [Tailscale Documentation](https://tailscale.com/kb/) - Tailscale setup

## Quick Reference Commands

```powershell
# Service management
Get-Service MaxLabJupyterLab                 # Check status
Start-Service MaxLabJupyterLab               # Start
Stop-Service MaxLabJupyterLab -Force         # Stop
Restart-Service MaxLabJupyterLab             # Restart

# Logging
Get-Content D:\apps\MaxLab\logs\service\jupyterlab-stdout.log -Tail 50
Get-Content D:\apps\MaxLab\logs\service\jupyterlab-stderr.log -Tail 50

# Port checking
netstat -ano | findstr :8888

# NSSM details
nssm status MaxLabJupyterLab
nssm dump MaxLabJupyterLab
```

## Support

For issues:
1. Check logs: `D:\apps\MaxLab\logs\service\`
2. Review Event Viewer: **Application** tab
3. Test manually: `cd D:\apps\MaxLab && ./start.ps1`
4. Check GitHub Actions workflow logs for deployment issues
