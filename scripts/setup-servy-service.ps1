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

function Find-Servy {
    # First try PATH
    try {
        $servyExe = Get-Command servy-cli.exe -ErrorAction SilentlyContinue
        if ($servyExe) {
            Write-Status "Found Servy in PATH: $($servyExe.Source)" "success"
            return $servyExe.Source
        }
    } catch {
        # Continue to search
    }

    # Search common locations
    $searchPaths = @(
        "$env:ProgramFiles\Servy\servy-cli.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\aelassas.Servy_*\servy-cli.exe",
        "$env:ProgramFiles\servy\servy-cli.exe",
        "C:\ProgramData\chocolatey\bin\servy-cli.exe"
    )

    foreach ($pathPattern in $searchPaths) {
        $resolvedPaths = Resolve-Path -Path $pathPattern -ErrorAction SilentlyContinue
        foreach ($resolved in $resolvedPaths) {
            if (Test-Path $resolved.Path) {
                Write-Status "Found Servy at: $($resolved.Path)" "success"
                return $resolved.Path
            }
        }
    }

    # Not found - attempt auto-installation via winget
    Write-Status "Servy not found, attempting auto-install via winget..." "warning"
    Write-Output ""
    
    try {
        Write-Status "Running: winget install -e --id aelassas.Servy" "info"
        $output = winget install -e --id aelassas.Servy --accept-source-agreements --accept-package-agreements 2>&1
        Write-Output $output
        Start-Sleep -Seconds 3
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # Try to find it again after install
        $servyExe = Get-Command servy-cli.exe -ErrorAction SilentlyContinue
        if ($servyExe) {
            Write-Status "Servy installed successfully: $($servyExe.Source)" "success"
            return $servyExe.Source
        }
        
        # Check common paths again
        foreach ($pathPattern in $searchPaths) {
            $resolvedPaths = Resolve-Path -Path $pathPattern -ErrorAction SilentlyContinue
            foreach ($resolved in $resolvedPaths) {
                if (Test-Path $resolved.Path) {
                    Write-Status "Found Servy at: $($resolved.Path)" "success"
                    return $resolved.Path
                }
            }
        }
        
        Write-Status "winget install completed but Servy not found, trying chocolatey..." "warning"
    } catch {
        Write-Status "winget auto-install failed: $_" "warning"
    }

    # Fallback: Try chocolatey
    Write-Output ""
    Write-Status "Attempting installation via Chocolatey..." "info"
    
    try {
        Write-Status "Running: choco install servy -y" "info"
        choco install servy -y 2>&1 | Out-Null
        Start-Sleep -Seconds 3
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # Try to find it again after choco install
        $servyExe = Get-Command servy-cli.exe -ErrorAction SilentlyContinue
        if ($servyExe) {
            Write-Status "Servy installed successfully: $($servyExe.Source)" "success"
            return $servyExe.Source
        }
        
        Write-Status "Chocolatey install completed but Servy not found" "warning"
    } catch {
        Write-Status "Chocolatey auto-install failed: $_" "warning"
    }

    # If we get here, both auto-install attempts failed
    Write-Output ""
    Write-Status "Servy could not be auto-installed. Please install manually:" "error"
    Write-Output ""
    Write-Output "Option 1 - Using Windows Package Manager (Recommended):"
    Write-Output "  winget install -e --id aelassas.Servy"
    Write-Output ""
    Write-Output "Option 2 - Using Chocolatey:"
    Write-Output "  choco install servy"
    Write-Output ""
    Write-Output "Option 3 - Manual Installation:"
    Write-Output "  1. Download from: https://github.com/aelassas/servy/releases"
    Write-Output "  2. Extract and add to PATH"
    Write-Output ""
    exit 1
}

function Stop-ExistingService {
    param([string]$ServiceName, [string]$ServyCli)
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($null -ne $service) {
        Write-Status "Existing service found. Stopping and removing..." "warning"
        
        if ($service.Status -eq "Running") {
            Write-Status "Stopping service..." "info"
            try {
                & "$ServyCli" stop --name="$ServiceName" 2>&1 | Out-Null
            } catch {
                # Fallback to Windows service command
                Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Seconds 3
        }
        
        Write-Status "Removing old service..." "info"
        try {
            & "$ServyCli" uninstall --name="$ServiceName" 2>&1
        } catch {
            # Fallback to sc.exe if Servy uninstall fails
            Write-Status "Servy uninstall failed, trying sc.exe..." "warning"
            sc.exe delete $ServiceName 2>&1 | Out-Null
        }
        Start-Sleep -Seconds 2
        
        # Verify service is removed
        $serviceCheck = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($null -eq $serviceCheck) {
            Write-Status "Service removed successfully" "success"
        } else {
            Write-Status "Warning: Service may still exist in registry" "warning"
        }
    } else {
        Write-Status "No existing service found" "info"
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
    param([string]$ServiceName, [string]$ServyCli, [string]$WrapperPath, [string]$LogsDir, [string]$DeployPath)
    
    Write-Status "Creating Servy service: $ServiceName" "info"
    
    # Find PowerShell executable (prefer pwsh, fallback to powershell)
    $pwshExe = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwshExe) {
        $psExe = $pwshExe.Source
    } else {
        $psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    }
    
    Write-Status "Using PowerShell: $psExe" "info"
    
    # Build the arguments for PowerShell
    $psArgs = "-NoProfile -NoLogo -ExecutionPolicy Bypass -File `"$WrapperPath`""
    
    # Install service with Servy
    Write-Status "Installing service with Servy CLI..." "info"
    
    $installResult = & "$ServyCli" install `
        --name="$ServiceName" `
        --displayName="MaxLab JupyterLab Service" `
        --description="MaxLab JupyterLab server running as a Windows service" `
        --path="$psExe" `
        --args="$psArgs" `
        --workingDirectory="$DeployPath" `
        --startType="Automatic" `
        2>&1
    
    Write-Output $installResult
    
    if ($LASTEXITCODE -ne 0) {
        Write-Status "Servy install command returned non-zero exit code: $LASTEXITCODE" "warning"
    }
    
    # Verify service was created
    Start-Sleep -Seconds 2
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        Write-Status "Service was not created. Check Servy output above." "error"
        exit 1
    }
    
    Write-Status "Service created successfully" "success"
}

function Start-MaxLabService {
    param([string]$ServiceName, [string]$ServyCli)
    
    Write-Status "Starting service..." "info"
    
    try {
        & "$ServyCli" start --name="$ServiceName" 2>&1 | Out-Null
        Start-Sleep -Seconds 5
        
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
Write-Status "MaxLab Servy Service Setup" "info"
Write-Output "=================================================="
Write-Output ""

# Validate deployment path
if (-not (Test-Path $DeployPath)) {
    Write-Status "Deployment path not found: $DeployPath" "error"
    exit 1
}
Write-Status "Deployment path exists: $DeployPath" "success"
Write-Output ""

# Find Servy
$servyExe = Find-Servy
Write-Output ""

# Create wrapper and get paths
$paths = Create-ServiceWrapper -DeployPath $DeployPath -ServiceName $ServiceName
Write-Output ""

# Stop existing service
Stop-ExistingService -ServiceName $ServiceName -ServyCli $servyExe
Write-Output ""

# Create service
Create-Service -ServiceName $ServiceName -ServyCli $servyExe -WrapperPath $paths.WrapperPath -LogsDir $paths.LogsDir -DeployPath $DeployPath
Write-Output ""

# Start service
$started = Start-MaxLabService -ServiceName $ServiceName -ServyCli $servyExe
Write-Output ""

if ($started) {
    Write-Status "Servy service setup completed successfully!" "success"
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
