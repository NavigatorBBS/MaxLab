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
    Write-Host "$color$Message$($colors.reset)"
}

function Find-NSSM {
    # First try PATH
    try {
        $nssmExe = Get-Command nssm.exe -ErrorAction SilentlyContinue
        if ($nssmExe) {
            Write-Status "Found NSSM in PATH: $($nssmExe.Source)" "success"
            return $nssmExe.Source
        }
    } catch {
        # Continue to search
    }

    # Search common locations
    $searchPaths = @(
        "C:\ProgramData\chocolatey\bin\nssm.exe",
        "C:\Program Files\NSSM\nssm.exe",
        "C:\Program Files\nssm\win64\nssm.exe",
        "C:\Program Files (x86)\nssm\win64\nssm.exe",
        "C:\nssm\nssm.exe",
        "C:\nssm\win64\nssm.exe",
        "$env:USERPROFILE\Tools\NSSM\nssm.exe",
        "$env:USERPROFILE\tools\nssm\win64\nssm.exe"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            Write-Status "Found NSSM at: $path" "success"
            return $path
        }
    }

    # Not found - attempt auto-installation via winget
    Write-Status "NSSM not found, attempting auto-install via winget..." "warning"
    Write-Output ""
    
    try {
        Write-Status "Running: winget install nssm" "info"
        $output = winget install nssm -e --accept-source-agreements 2>&1
        Start-Sleep -Seconds 2
        
        # Try to find it again after install attempt
        foreach ($path in $searchPaths) {
            if (Test-Path $path) {
                Write-Status "NSSM installed successfully at: $path" "success"
                return $path
            }
        }
        
        # Check PATH after install
        try {
            $nssmExe = Get-Command nssm.exe -ErrorAction SilentlyContinue
            if ($nssmExe) {
                Write-Status "Found NSSM in PATH after install: $($nssmExe.Source)" "success"
                return $nssmExe.Source
            }
        } catch {
            # Continue to error handling
        }
        
        Write-Status "winget install completed but NSSM not found, trying chocolatey..." "warning"
    } catch {
        Write-Status "winget auto-install failed: $_" "warning"
    }

    # Fallback: Try chocolatey
    Write-Output ""
    Write-Status "Attempting installation via Chocolatey..." "info"
    
    try {
        Write-Status "Running: choco install nssm -y" "info"
        choco install nssm -y 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        
        # Try to find it again after choco install
        foreach ($path in $searchPaths) {
            if (Test-Path $path) {
                Write-Status "NSSM installed successfully at: $path" "success"
                return $path
            }
        }
        
        # Check PATH after install
        try {
            $nssmExe = Get-Command nssm.exe -ErrorAction SilentlyContinue
            if ($nssmExe) {
                Write-Status "Found NSSM in PATH after install: $($nssmExe.Source)" "success"
                return $nssmExe.Source
            }
        } catch {
            # Continue to error handling
        }
        
        Write-Status "Chocolatey install completed but NSSM not found" "warning"
    } catch {
        Write-Status "Chocolatey auto-install failed: $_" "warning"
    }

    # If we get here, both auto-install attempts failed
    Write-Output ""
    Write-Status "NSSM could not be auto-installed. Please install manually:" "error"
    Write-Output ""
    Write-Output "Option 1 - Using Chocolatey (Recommended):"
    Write-Output "  choco install nssm -y"
    Write-Output ""
    Write-Output "Option 2 - Using Windows Package Manager:"
    Write-Output "  winget install nssm"
    Write-Output ""
    Write-Output "Option 3 - Manual Installation:"
    Write-Output "  1. Download from: https://nssm.cc/download"
    Write-Output "  2. Extract to C:\Program Files\NSSM"
    Write-Output "  3. Add C:\Program Files\NSSM to PATH environment variable"
    Write-Output ""
    exit 1
}

function Stop-ExistingService {
    param([string]$ServiceName, [string]$NSS)
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($null -ne $service) {
        Write-Status "Existing service found. Stopping and removing..." "warning"
        
        if ($service.Status -eq "Running") {
            Write-Status "Stopping service..." "info"
            Stop-Service -Name $ServiceName -Force
            Start-Sleep -Seconds 2
        }
        
        Write-Status "Removing old service..." "info"
        & "$NSS" remove $ServiceName confirm
        Start-Sleep -Seconds 1
    }
}

function Create-ServiceWrapper {
    param([string]$DeployPath, [string]$ServiceName)
    
    $logsDir = Join-Path $DeployPath "logs" "service"
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    
    $wrapperPath = Join-Path $DeployPath "run-jupyter.ps1"
    
    $wrapperContent = @"
# MaxLab JupyterLab Service Wrapper
# Loads environment and runs start.ps1
param()

`$ErrorActionPreference = "Stop"
`$deployPath = "$DeployPath"
`$logsDir = "$logsDir"

# Change to deployment directory
Set-Location `$deployPath

# Load .env variables
`$envPath = Join-Path `$deployPath ".env"
if (Test-Path `$envPath) {
    Get-Content `$envPath | ForEach-Object {
        `$line = `$_.Trim()
        if (-not `$line -or `$line.StartsWith("#")) { return }
        if (`$line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$") {
            `$name = `$matches[1]
            `$value = `$matches[2].Trim('"''')
            `$existing = Get-Item -Path "Env:\`$name" -ErrorAction SilentlyContinue
            if (`$null -eq `$existing -or [string]::IsNullOrWhiteSpace(`$existing.Value)) {
                Set-Item -Path "Env:\`$name" -Value `$value
            }
        }
    }
}

# Execute start.ps1
try {
    & .\start.ps1 2>&1 | Tee-Object -FilePath "`$logsDir\jupyter.log"
} catch {
    `$error[0] | Out-File -FilePath "`$logsDir\error.log" -Append
    throw
}
"@
    
    Set-Content -Path $wrapperPath -Value $wrapperContent -Force
    return @{
        WrapperPath = $wrapperPath
        LogsDir = $logsDir
    }
}

function Create-Service {
    param([string]$ServiceName, [string]$NSSM, [string]$WrapperPath, [string]$LogsDir)
    
    Write-Status "Creating NSSM service: $ServiceName" "info"
    
    # Find PowerShell executable (prefer pwsh, fallback to powershell)
    $pwshExe = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwshExe) {
        $psExe = $pwshExe.Source
    } else {
        $psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    }
    
    Write-Status "Using PowerShell: $psExe" "info"
    
    # Install service with PowerShell as the application
    & "$NSSM" install $ServiceName $psExe
    & "$NSSM" set $ServiceName AppParameters "-NoProfile -NoLogo -ExecutionPolicy Bypass -File `"$WrapperPath`""
    & "$NSSM" set $ServiceName AppDirectory (Split-Path $WrapperPath -Parent)
    & "$NSSM" set $ServiceName AppStdout "$LogsDir\jupyterlab-stdout.log"
    & "$NSSM" set $ServiceName AppStderr "$LogsDir\jupyterlab-stderr.log"
    & "$NSSM" set $ServiceName AppRotateFiles 1
    & "$NSSM" set $ServiceName AppRotateOnline 1
    & "$NSSM" set $ServiceName AppRotateSeconds 86400
    & "$NSSM" set $ServiceName AppRotateBytes 10485760
    & "$NSSM" set $ServiceName AppRestartDelay 5000
}

function Start-MaxLabService {
    param([string]$ServiceName)
    
    Write-Status "Starting service..." "info"
    
    try {
        Start-Service -Name $ServiceName
        Start-Sleep -Seconds 3
        
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq "Running") {
            Write-Status "Service is running" "success"
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
Write-Status "Deployment path exists: $DeployPath" "success"
Write-Output ""

# Find NSSM
$nssmExe = Find-NSSM
Write-Output ""

# Create wrapper and get paths
$paths = Create-ServiceWrapper -DeployPath $DeployPath -ServiceName $ServiceName
Write-Output ""

# Stop existing service
Stop-ExistingService -ServiceName $ServiceName -NSS $nssmExe
Write-Output ""

# Create service
Create-Service -ServiceName $ServiceName -NSSM $nssmExe -WrapperPath $paths.WrapperPath -LogsDir $paths.LogsDir
Write-Output ""

# Start service
$started = Start-MaxLabService -ServiceName $ServiceName
Write-Output ""

if ($started) {
    Write-Status "NSSM service setup completed successfully!" "success"
    Write-Status "Service Name: $ServiceName" "info"
    Write-Status "Service Status: Running" "info"
    Write-Status "Logs Location: $($paths.LogsDir)" "info"
    Write-Output ""
    exit 0
} else {
    Write-Status "Service created but may not be running yet" "warning"
    Write-Output ""
    exit 1
}
