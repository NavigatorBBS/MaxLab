# MaxLab Deployment Pre-Flight Checklist

## Overview

This checklist ensures your Windows server runner is fully prepared for automated MaxLab deployments. Follow this **once per server setup** before attempting your first deployment.

## Quick Validation

Run the automated validation script:

```powershell
cd C:\Users\chris\code\MaxLab
.\scripts\validate-deployment-ready.ps1
```

This checks all requirements and shows exactly what's missing.

---

## Manual Checklist

### ✅ System Prerequisites

- [ ] **Windows Server 2016+** or Windows 10/11
  - Deployments require Windows-specific PowerShell features
  - Verify: `Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption`

- [ ] **Admin/PowerShell Access**
  - Need admin rights to install NSSM and manage services
  - Verify: Run PowerShell as Administrator

- [ ] **Internet Access**
  - Required for git clone, conda package management
  - Verify: `ping github.com`

---

### 🔧 Required Software

#### 1. Git

**Required for**: Cloning/updating repository

```powershell
# Check installation
git --version

# If not installed, use Chocolatey
choco install git -y

# Or download: https://git-scm.com/download/win
```

---

#### 2. Miniconda3

**Required for**: Python environment, conda, JupyterLab

```powershell
# Check installation
conda --version

# If not installed:
# 1. Download: https://docs.conda.io/projects/miniconda/en/latest/
# 2. Install to: C:\Users\<username>\miniconda3
# 3. Restart terminal/runner for PATH to update
```

**Important**: Restart your GitHub Actions runner after installing Miniconda3.

---

#### 2a. Add Conda to PATH (Critical)

**Why**: The validation script and deployment process require `conda` to be in your system PATH.

**Check if conda is in PATH:**
```powershell
conda --version
```

If this works, conda is already in PATH. If not, add it manually:

```powershell
# Find conda installation location
Get-ChildItem -Path "C:\Users" -Filter "miniconda3" -Recurse -Directory

# Example: If installed at C:\Users\chris\miniconda3
# Add to PATH (run as Administrator):
$path = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($path -notlike "*miniconda3*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$path;C:\Users\chris\miniconda3;C:\Users\chris\miniconda3\Scripts",
        [EnvironmentVariableTarget]::Machine
    )
}

# After adding to PATH, RESTART the GitHub Actions runner service
Restart-Service "GitHub*"
```

**Verify it worked:**
```powershell
# Restart PowerShell first
$env:Path -split ";" | findstr miniconda3
# Should show your miniconda3 path
```

---

#### 3. Conda Environment: `maxlab`

**Required for**: Python packages, JupyterLab

```powershell
# Check if environment exists
conda env list

# If maxlab environment doesn't exist, create it:
cd C:\Users\chris\code\MaxLab
.\setup.ps1
```

**What setup.ps1 does**:
- Creates `maxlab` conda environment (Python 3.12)
- Installs JupyterLab and dependencies
- Installs pre-commit hooks
- Sets up .env file

---

#### 4. NSSM (Non-Sucking Service Manager)

**Required for**: Running JupyterLab as Windows service

```powershell
# Check installation
nssm.exe --version

# If not found, install via Chocolatey (recommended):
choco install nssm -y

# OR download manually:
# 1. Download: https://nssm.cc/download
# 2. Extract to: C:\tools\nssm\
# 3. Add to PATH:
$path = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($path -notlike "*C:\tools\nssm*") {
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$path;C:\tools\nssm\win64",
        [EnvironmentVariableTarget]::Machine
    )
}

# After PATH change, RESTART the system or GitHub Actions runner service
```

**Troubleshooting**:
- If NSSM still not found after install, check PATH:
  ```powershell
  $env:Path -split ";" | findstr nssm
  ```
- Restart GitHub Actions runner if not in PATH:
  ```powershell
  Restart-Service "GitHub*"
  ```

---

#### 5. JupyterLab (in maxlab environment)

**Required for**: Deployment service

```powershell
# Check installation
conda run -n maxlab jupyter --version

# If not found, should be installed by setup.ps1
# Or install manually:
conda activate maxlab
pip install jupyterlab
```

---

### 📁 Directory Structure

- [ ] **D:\apps\ directory exists** (or alternative deployment directory)
  ```powershell
  # Create if missing
  New-Item -ItemType Directory -Path "D:\apps" -Force
  ```

- [ ] **Write permissions** on D:\apps\
  ```powershell
  # Verify write access
  New-Item -Path "D:\apps\.test-write" -ItemType File
  Remove-Item -Path "D:\apps\.test-write"
  ```

---

### 🔐 GitHub Actions Runner

- [ ] **Runner is installed** on Windows server
  - Instructions: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners
  
- [ ] **Runner has label**: `windows-server`
  - Verify in GitHub Actions runner configuration

- [ ] **Runner service is running**
  ```powershell
  Get-Process -Name "Runner.Listener"
  
  # If not running, start it
  Start-Service "GitHub*"
  ```

- [ ] **Runner is online** in GitHub
  - Check: Repository Settings → Actions → Runners
  - Should show status: ✅ Idle (or Running)

---

### 🌐 Network & Ports

- [ ] **Outbound HTTPS (port 443)** is open
  - Required for: GitHub access, package downloads
  - Test: `Invoke-WebRequest https://github.com -UseBasicParsing`

- [ ] **Ports 8888 and 8889 are available**
  - Production JupyterLab: 8888
  - Test JupyterLab: 8889
  ```powershell
  # Check what's using ports
  netstat -ano | findstr :8888
  netstat -ano | findstr :8889
  ```

---

### 🔐 Tailscale (VPN Networking)

- [ ] **Tailscale is installed**
   ```powershell
   # Check installation
   tailscale.exe version
   
   # If not found, install via Chocolatey (recommended):
   choco install tailscale -y
   
   # OR download: https://tailscale.com/download/windows
   ```

- [ ] **Tailscale is logged in**
   ```powershell
   # Check status
   tailscale.exe status
   
   # If not logged in, authenticate:
   tailscale.exe login
   # Follow the browser prompt to authorize
   ```

- [ ] **GitHub Actions has Tailscale secrets configured**
   - Add to GitHub repo **Settings → Secrets and variables → Actions**
   - **Production environment**: `TAILSCALE_AUTHKEY` (ephemeral auth token)
   - **Test environment**: `TAILSCALE_AUTHKEY` (ephemeral auth token)
   - Get tokens from: https://login.tailscale.com/admin/settings/keys
   - Create ephemeral keys with appropriate expiration (e.g., 90 days)

**Why Tailscale?**: Provides secure network access to JupyterLab instances via private network (tailnet).

---

### 💾 Disk Space

- [ ] **At least 10 GB free** on deployment drive (D:\)
  ```powershell
  Get-Volume -DriveLetter D | Select-Object SizeRemaining
  ```

---

### ⚙️ PowerShell Settings

- [ ] **PowerShell Execution Policy** allows scripts
  ```powershell
  # Check current policy
  Get-ExecutionPolicy
  
  # If "Restricted", change to "RemoteSigned" (or "Bypass" for testing)
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  ```

---

## Configuration Files

### .env Files

Each deployment needs a `.env` file with port configuration:

**Production** - `D:\apps\MaxLab\.env`:
```env
JUPYTER_PORT=8888
JUPYTER_NOTEBOOK_DIR=workspace
```

**Test** - `D:\apps\MaxLabTest\.env`:
```env
JUPYTER_PORT=8889
JUPYTER_NOTEBOOK_DIR=workspace
```

---

## First-Time Deployment Steps

Once all checklist items are complete:

### 1. Verify Everything is Ready

```powershell
.\scripts\validate-deployment-ready.ps1
```

All checks should pass.

### 2. Create or Verify test Branch

```powershell
# Check if test branch exists
git branch -r | grep test

# If not, create it locally and push
git checkout -b test
git push -u origin test
```

### 3. Test Production Deployment

```powershell
# Push to main branch
git push origin main
```

**Monitor in GitHub**:
- Actions tab → Deploy MaxLab workflow
- Watch for: Python Linting → Notebook Outputs → Deploy to Production
- Should complete in 2-5 minutes

**Verify on server**:
```powershell
Get-Service MaxLabJupyterLab
# Should show: Status=Running

# Check logs
Get-Content D:\apps\MaxLab\logs\service\jupyterlab-stdout.log -Tail 50
```

### 4. Test Test Deployment

```powershell
# Make a change, push to test branch
git push origin test
```

**Verify on server**:
```powershell
Get-Service MaxLabJupyterLabTest
# Should show: Status=Running

# Check logs
Get-Content D:\apps\MaxLabTest\logs\service\jupyterlab-stdout.log -Tail 50
```

### 5. Verify Both Services Run Simultaneously

```powershell
# Both should be Running
Get-Service MaxLabJupyterLab, MaxLabJupyterLabTest

# Check ports
netstat -ano | findstr LISTENING | findstr :8888
netstat -ano | findstr LISTENING | findstr :8889

# Both ports should have active connections
```

---

## Troubleshooting

### "NSSM not found" Error

**Cause**: NSSM isn't installed or not in PATH

**Solution**:
```powershell
# Install NSSM
choco install nssm -y

# OR add to PATH manually
$path = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("Path", "$path;C:\tools\nssm\win64", [EnvironmentVariableTarget]::Machine)

# Restart GitHub Actions runner
Restart-Service "GitHub*" -Force
```

### Service Won't Start

**Check logs**:
```powershell
Get-Content D:\apps\MaxLab\logs\service\jupyterlab-stderr.log -Tail 100
```

**Common issues**:
- Port already in use: Change JUPYTER_PORT in .env
- Conda environment missing: Run setup.ps1
- Permissions issue: Ensure runner user has write access to D:\apps\

### Port Already in Use

**Check what's using the port**:
```powershell
netstat -ano | findstr :8888
tasklist | findstr <PID>

# Kill if needed (careful!)
Stop-Process -Id <PID> -Force
```

**Or configure different port**:
```powershell
# Edit D:\apps\MaxLab\.env
JUPYTER_PORT=9000

# Restart service
Restart-Service MaxLabJupyterLab
```

### Deployment Validation Fails

**Run validation script**:
```powershell
.\scripts\validate-deployment-ready.ps1
```

Fix any reported issues, then re-run to verify.

---

## Support

If issues persist:

1. **Check deployment logs**: 
   - GitHub Actions workflow logs (red X shows where it failed)
   - Service logs: `D:\apps\MaxLab\logs\service\*.log`

2. **Review documentation**:
   - [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment instructions
   - [NSSM_SETUP.md](NSSM_SETUP.md) - Service management

3. **Run validation script**: 
   ```powershell
   .\scripts\validate-deployment-ready.ps1
   ```

---

## Checklist Completion

When all items are checked:

- ✅ Server is ready for first deployment
- ✅ Run: `git push origin main` to test
- ✅ Monitor GitHub Actions for deployment
- ✅ Verify services are running
- ✅ Ready for ongoing automated deployments

**Next**: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for deployment instructions.
