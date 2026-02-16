# MaxLab Servy Service Setup Guide

## Overview

MaxLab runs JupyterLab as Windows services using **Servy** (a modern Windows service manager). This provides:
- ✅ Automatic startup on server reboot
- ✅ Auto-restart if JupyterLab crashes
- ✅ Centralized logging to files
- ✅ Easy service management via CLI
- ✅ Support for multiple services (production + test) on same server
- ✅ Reliable service deletion and recreation

## Services

MaxLab supports two concurrent services:

| Service | Directory | Branch | Default Port |
|---------|-----------|--------|--------------|
| `MaxLabJupyterLab` | `D:\apps\MaxLab` | `main` | 8888 |
| `MaxLabJupyterLabTest` | `D:\apps\MaxLabTest` | `test` | 8889 |

Both services can run simultaneously on the same Windows server.

## Automatic Setup via Deployment

When you run the GitHub Actions deployment workflow, the appropriate service is automatically:
1. **Created** with the correct name (production or test)
2. **Configured** with proper logging and auto-restart
3. **Started** and verified as running

No manual Servy commands needed—the workflow handles everything!

## Service Details

### Production Service

| Property | Value |
|----------|-------|
| **Service Name** | `MaxLabJupyterLab` |
| **Directory** | `D:\apps\MaxLab` |
| **Service Type** | Windows Service |
| **Auto Start** | Yes (starts on reboot) |
| **Auto Restart** | Yes (on crash) |
| **Log Location** | `D:\apps\MaxLab\logs\service\` |
| **Port** | 8888 (from `JUPYTER_PORT` in `.env`) |
| **Environment** | `maxlab` conda environment |

### Test Service

| Property | Value |
|----------|-------|
| **Service Name** | `MaxLabJupyterLabTest` |
| **Directory** | `D:\apps\MaxLabTest` |
| **Service Type** | Windows Service |
| **Auto Start** | Yes (starts on reboot) |
| **Auto Restart** | Yes (on crash) |
| **Log Location** | `D:\apps\MaxLabTest\logs\service\` |
| **Port** | 8889 (from `JUPYTER_PORT` in `.env`, must differ from production) |
| **Environment** | `maxlab` conda environment |

## Important: Port Configuration

To run both services simultaneously, they must use different ports. Configure in each deployment's `.env` file:

**Production `.env` (D:\apps\MaxLab\.env):**
```
JUPYTER_PORT=8888
```

**Test `.env` (D:\apps\MaxLabTest\.env):**
```
JUPYTER_PORT=8889
```

If ports conflict, one service will fail to start. See [Troubleshooting](#port-already-in-use) section for solutions.

## Managing the Service

### Check Service Status

**Production:**
```powershell
# Using Windows Services
Get-Service MaxLabJupyterLab

# Using Servy CLI (detailed)
servy-cli status --name=MaxLabJupyterLab
```

**Test:**
```powershell
# Using Windows Services
Get-Service MaxLabJupyterLabTest

# Using Servy CLI (detailed)
servy-cli status --name=MaxLabJupyterLabTest
```

**Output meanings:**
- `Running` = Service is active, JupyterLab is running
- `Stopped` = Service is not running
- `Paused` = Service is paused

### Start the Service

**Production:**
```powershell
# Using Windows Services
Start-Service MaxLabJupyterLab

# Or using Servy CLI
servy-cli start --name=MaxLabJupyterLab
```

**Test:**
```powershell
# Using Windows Services
Start-Service MaxLabJupyterLabTest

# Or using Servy CLI
servy-cli start --name=MaxLabJupyterLabTest
```

### Stop the Service

**Production:**
```powershell
# Using Windows Services
Stop-Service MaxLabJupyterLab -Force

# Or using Servy CLI
servy-cli stop --name=MaxLabJupyterLab
```

**Test:**
```powershell
# Using Windows Services
Stop-Service MaxLabJupyterLabTest -Force

# Or using Servy CLI
servy-cli stop --name=MaxLabJupyterLabTest
```

### Restart the Service

**Production:**
```powershell
# Using Windows Services
Restart-Service MaxLabJupyterLab

# Or using Servy CLI
servy-cli restart --name=MaxLabJupyterLab
```

**Test:**
```powershell
# Using Windows Services
Restart-Service MaxLabJupyterLabTest

# Or using Servy CLI
servy-cli restart --name=MaxLabJupyterLabTest
```

## Viewing Logs

### View Recent Logs (Last 50 Lines)

**Production:**
```powershell
Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stdout.log" -Tail 50
```

**Test:**
```powershell
Get-Content "D:\apps\MaxLabTest\logs\service\jupyterlab-stdout.log" -Tail 50
```

### Follow Logs in Real-Time (Tail)

**Production:**
```powershell
# Using Get-Content with -Wait (Ctrl+C to stop)
Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stdout.log" -Tail 1 -Wait

# Or use PowerShell tail (if available)
tail -f "D:\apps\MaxLab\logs\service\jupyterlab-stdout.log"
```

**Test:**
```powershell
# Using Get-Content with -Wait (Ctrl+C to stop)
Get-Content "D:\apps\MaxLabTest\logs\service\jupyterlab-stdout.log" -Tail 1 -Wait

# Or use PowerShell tail (if available)
tail -f "D:\apps\MaxLabTest\logs\service\jupyterlab-stdout.log"
```

### View Error Logs

**Production:**
```powershell
Get-Content "D:\apps\MaxLab\logs\service\jupyterlab-stderr.log" -Tail 50
```

**Test:**
```powershell
Get-Content "D:\apps\MaxLabTest\logs\service\jupyterlab-stderr.log" -Tail 50
```

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

**Symptom**: Logs show "Address already in use" for port 8888 or 8889

**Common cause with dual services**: Both production and test services trying to use the same port.

**Solution 1 - Check which service/process is using the port:**
```powershell
# Check port 8888
netstat -ano | findstr :8888

# Check port 8889
netstat -ano | findstr :8889
```

**Solution 2 - Ensure production and test use different ports:**
1. Edit production `.env` file (`D:\apps\MaxLab\.env`):
   ```
   JUPYTER_PORT=8888
   ```
2. Edit test `.env` file (`D:\apps\MaxLabTest\.env`):
   ```
   JUPYTER_PORT=8889
   ```
3. Restart both services:
   ```powershell
   Restart-Service MaxLabJupyterLab
   Restart-Service MaxLabJupyterLabTest
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

### View Service Help
```powershell
servy-cli help
```

### Remove Service Completely
```powershell
# Stop service first
Stop-Service MaxLabJupyterLab

# Remove via Servy CLI
servy-cli uninstall --name=MaxLabJupyterLab

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

## Deployment Workflow Integration

The GitHub Actions deployment workflow automatically:

1. **Stops** any existing service via Servy CLI
2. **Removes** the old service (clean uninstall)
3. **Creates** a new service with latest code
4. **Configures** logging and auto-start
5. **Starts** the service
6. **Verifies** it's running

This happens in the "Setup Servy JupyterLab Service" step of the workflow.

## Installing Servy

Servy is automatically installed during deployment if not present. For manual installation:

**Option 1 - Windows Package Manager (Recommended):**
```powershell
winget install -e --id aelassas.Servy
```

**Option 2 - Chocolatey:**
```powershell
choco install servy
```

**Option 3 - Manual Download:**
1. Download from: https://github.com/aelassas/servy/releases
2. Extract and add to PATH

## Related Documentation

- [MaxLab Deployment Guide](DEPLOYMENT_GUIDE.md) - Overall deployment process
- [MaxLab README](README.md) - Project overview
- [Servy Documentation](https://github.com/aelassas/servy/wiki) - Detailed Servy reference
- [Tailscale Documentation](https://tailscale.com/kb/) - Tailscale setup

## Quick Reference Commands

```powershell
# Service management
Get-Service MaxLabJupyterLab                 # Check status
Start-Service MaxLabJupyterLab               # Start
Stop-Service MaxLabJupyterLab -Force         # Stop
Restart-Service MaxLabJupyterLab             # Restart

# Servy CLI
servy-cli status --name=MaxLabJupyterLab     # Detailed status
servy-cli start --name=MaxLabJupyterLab      # Start
servy-cli stop --name=MaxLabJupyterLab       # Stop
servy-cli restart --name=MaxLabJupyterLab    # Restart
servy-cli uninstall --name=MaxLabJupyterLab  # Remove

# Logging
Get-Content D:\apps\MaxLab\logs\service\jupyterlab-stdout.log -Tail 50
Get-Content D:\apps\MaxLab\logs\service\jupyterlab-stderr.log -Tail 50

# Port checking
netstat -ano | findstr :8888
```

## Support

For issues:
1. Check logs: `D:\apps\MaxLab\logs\service\`
2. Test manually: `cd D:\apps\MaxLab && ./start.ps1`
3. Check GitHub Actions workflow logs for deployment issues
