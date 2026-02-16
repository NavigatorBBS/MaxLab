param (
    [string]$DeployPath = "D:\apps\MaxLab",
    [string]$ServiceName = "MaxLabJupyterLab"
)

$ErrorActionPreference = "Stop"

# Color definitions
$colors = @{
    success  = "`e[38;2;76;175;80m"
    error    = "`e[38;2;244;67;54m"
    warning  = "`e[38;2;255;152;0m"
    info     = "`e[38;2;33;150;243m"
    reset    = "`e[0m"
}

function Write-Status {
    param([string]$Message, [string]$Type = "info")
    $color = $colors[$Type]
    Write-Output "$color$Message$($colors.reset)"
}

function Find-NSSM {
    # Check multiple common locations
    $possiblePaths = @(
        "C:\tools\nssm\win64\nssm.exe",
        "C:\Program Files\nssm\win64\nssm.exe",
        "C:\Program Files (x86)\nssm\win64\nssm.exe",
        "$env:USERPROFILE\tools\nssm\win64\nssm.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Status "Found NSSM at: $path" "success"
            return $path
        }
    }

    # Try to find in PATH
    try {
        $nssmExe = Get-Command nssm.exe -ErrorAction SilentlyContinue
        if ($nssmExe) {
            Write-Status "Found NSSM in PATH: $($nssmExe.Source)" "success"
            return $nssmExe.Source
        }
    } catch {
        # Continue to error
    }

    Write-Status "NSSM not found. Please install NSSM or add it to PATH." "error"
    exit 1
}

function Stop-ExistingService {
    param([string]$ServiceName, [string]$NSSM)

    # Check if service exists
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($null -ne $service) {
        Write-Status "Existing service found. Stopping and removing..." "warning"

        try {
            if ($service.Status -eq "Running") {
                Write-Status "Stopping service '$ServiceName'..." "info"
                Stop-Service -Name $ServiceName -Force
                Start-Sleep -Seconds 2
            }

            Write-Status "Removing service '$ServiceName'..." "info"
            & $NSSM remove $ServiceName confirm
            Start-Sleep -Seconds 1
        } catch {
            Write-Status "Error stopping/removing service: $_" "error"
            exit 1
        }
    }
}

function Create-ServiceWrapper {
    param(
        [string]$DeployPath,
        [string]$WrapperPath
    )

    $wrapperContent = @"
# Wrapper script for NSSM service
# This script is invoked by NSSM to start JupyterLab

param()

`$ErrorActionPreference = "Stop"

# Set working directory
Set-Location "$DeployPath"

# Add Miniconda to PATH
`$minicondaPath = "`$env:USERPROFILE\miniconda3"
`$minicondaScriptsPath = "`$minicondaPath\Scripts"
if (-not (`$env:PATH -like "*`$minicondaScriptsPath*")) {
    `$env:PATH = "`$minicondaScriptsPath;`$minicondaPath;`$env:PATH"
}

# Load environment variables from .env if it exists
`$envPath = Join-Path "$DeployPath" ".env"
if (Test-Path `$envPath) {
    Get-Content `$envPath | ForEach-Object {
        `$line = `$_.Trim()
        if (-not `$line -or `$line.StartsWith("#")) { return }
        
        if (`$line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*`$") {
            `$name = `$matches[1]
            `$value = `$matches[2].Trim()
            if ((`$value.StartsWith('"') -and `$value.EndsWith('"')) -or (`$value.StartsWith("'") -and `$value.EndsWith("'"))) {
                `$value = `$value.Substring(1, `$value.Length - 2)
            }
            Set-Item -Path "Env:`$name" -Value `$value -ErrorAction SilentlyContinue
        }
    }
}

# Initialize conda
`$condaRoot = `$env:CONDA_ROOT
if (-not `$condaRoot -and `$env:CONDA_EXE) {
    `$condaRoot = Split-Path -Parent (Split-Path -Parent `$env:CONDA_EXE)
}
if (-not `$condaRoot) {
    `$condaRoot = "`$env:USERPROFILE\miniconda3"
}

`$modulePath = Join-Path `$condaRoot "shell\condabin\Conda.psm1"
if (Test-Path `$modulePath) {
    Import-Module `$modulePath -ErrorAction SilentlyContinue
}

# Activate conda environment
`$env:CONDA_PREFIX = Join-Path `$minicondaPath "envs" "maxlab"
`$env:CONDA_DEFAULT_ENV = "maxlab"
`$env:PATH = "`$(Join-Path `$env:CONDA_PREFIX 'Scripts');`$(Join-Path `$env:CONDA_PREFIX 'Library\mingw-w64\bin');`$(Join-Path `$env:CONDA_PREFIX 'Library\usr\bin');`$(Join-Path `$env:CONDA_PREFIX 'Library\bin');`$env:PATH"

# Get configuration from environment
`$port = if (`$env:JUPYTER_PORT) { `$env:JUPYTER_PORT } else { 8888 }
`$notebookDir = if (`$env:JUPYTER_NOTEBOOK_DIR) { `$env:JUPYTER_NOTEBOOK_DIR } else { "workspace" }

# Resolve notebook directory
if (-not [System.IO.Path]::IsPathRooted(`$notebookDir)) {
    `$notebookDir = Join-Path "$DeployPath" `$notebookDir
}

# Start JupyterLab
Write-Host "Starting JupyterLab on port `$port with notebook dir `$notebookDir"
jupyter lab `
  --port `$port `
  --notebook-dir `$notebookDir `
  --ServerApp.allow_remote_access=True `
  --ServerApp.allow_origin="*" `
  --ServerApp.trust_xheaders=True `
  --ServerApp.token='' `
  --ServerApp.password='' `
  --ServerApp.base_url="/"
"@

    Set-Content -Path $WrapperPath -Value $wrapperContent -Force
    Write-Status "Created service wrapper at: $WrapperPath" "success"
}

function Create-Service {
    param(
        [string]$ServiceName,
        [string]$NSSM,
        [string]$WrapperPath,
        [string]$LogDir
    )

    Write-Status "Creating NSSM service '$ServiceName'..." "info"

    try {
        # Install service
        & $NSSM install $ServiceName powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$WrapperPath`""
        
        # Configure service appearance
        & $NSSM set $ServiceName DisplayName "MaxLab JupyterLab Service"
        & $NSSM set $ServiceName Description "JupyterLab service for MaxLab data science environment"

        # Configure logging
        $stdoutLog = Join-Path $LogDir "jupyterlab-stdout.log"
        $stderrLog = Join-Path $LogDir "jupyterlab-stderr.log"
        
        & $NSSM set $ServiceName AppStdoutCreationDisposition 4  # Open always
        & $NSSM set $ServiceName AppStderrCreationDisposition 4  # Open always
        & $NSSM set $ServiceName AppStdout "$stdoutLog"
        & $NSSM set $ServiceName AppStderr "$stderrLog"
        & $NSSM set $ServiceName AppRotateFiles 1                # Enable rotation
        & $NSSM set $ServiceName AppRotateOnline 1               # Rotate while running
        & $NSSM set $ServiceName AppRotateSeconds 0              # Size-based rotation
        & $NSSM set $ServiceName AppRotateBytes 10485760         # 10 MB per log

        # Configure auto-restart
        & $NSSM set $ServiceName AppRestartDelay 5000             # 5 seconds delay
        & $NSSM set $ServiceName AppThrottle 1500                # Throttle after 1.5s delay

        # Configure Event Log
        & $NSSM set $ServiceName Type SERVICE_WIN32_OWN_PROCESS
        & $NSSM set $ServiceName Start SERVICE_AUTO_START

        Write-Status "Service created successfully" "success"
        Write-Status "Log files: $stdoutLog, $stderrLog" "info"

    } catch {
        Write-Status "Failed to create service: $_" "error"
        exit 1
    }
}

function Start-Service {
    param([string]$ServiceName)

    Write-Status "Starting service '$ServiceName'..." "info"

    try {
        Start-Service -Name $ServiceName
        Start-Sleep -Seconds 3

        # Verify service is running
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq "Running") {
            Write-Status "✓ Service is running" "success"
            return $true
        } else {
            Write-Status "Service status: $($service.Status)" "warning"
            return $false
        }
    } catch {
        Write-Status "Failed to start service: $_" "error"
        return $false
    }
}

# Main execution
Write-Output ""
Write-Status "MaxLab NSSM Service Setup" "info"
Write-Output "=================================================="
Write-Output ""

# Validate deployment path
if (-not (Test-Path $DeployPath)) {
    Write-Status "Deployment path not found: $DeployPath" "error"
    exit 1
}
Write-Status "✓ Deployment path exists: $DeployPath" "success"

# Find NSSM
$nssmExe = Find-NSSM
Write-Output ""

# Setup directories
$logsDir = Join-Path $DeployPath "logs\service"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}
Write-Status "✓ Logs directory ready: $logsDir" "success"

# Create wrapper script
$wrapperPath = Join-Path $DeployPath "scripts\maxlab-service-wrapper.ps1"
Create-ServiceWrapper -DeployPath $DeployPath -WrapperPath $wrapperPath
Write-Output ""

# Stop existing service if it exists
Stop-ExistingService -ServiceName $ServiceName -NSSM $nssmExe
Write-Output ""

# Create new service
Create-Service -ServiceName $ServiceName -NSSM $nssmExe -WrapperPath $wrapperPath -LogDir $logsDir
Write-Output ""

# Start service
$started = Start-Service -ServiceName $ServiceName
Write-Output ""

if ($started) {
    Write-Status "✓ NSSM service setup completed successfully!" "success"
    Write-Status "Service Name: $ServiceName" "info"
    Write-Status "Service Status: Running" "info"
    Write-Status "Logs Location: $logsDir" "info"
    Write-Output ""
    Write-Status "To check service status:" "info"
    Write-Output "  nssm status $ServiceName"
    Write-Output ""
    Write-Status "To stop service:" "info"
    Write-Output "  nssm stop $ServiceName"
    Write-Output ""
    Write-Status "To restart service:" "info"
    Write-Output "  nssm restart $ServiceName"
    Write-Output ""
    Write-Status "To view logs:" "info"
    Write-Output "  Get-Content '$logsDir\jupyterlab-stdout.log' -Tail 50"
    Write-Output ""
    exit 0
} else {
    Write-Status "⚠ Service created but may not be running yet. Check logs:" "warning"
    Write-Output "  Get-Content '$logsDir\jupyterlab-stdout.log' -Tail 50"
    Write-Output ""
    exit 1
}
