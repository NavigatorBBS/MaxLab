param (
    [string]$DeployPath = "D:\apps\MaxLab",
    [string]$TaskName = "MaxLabJupyterLab"
)

$ErrorActionPreference = "SilentlyContinue"

$logsDir = Join-Path $DeployPath "logs" "service"
$logFile = Join-Path $logsDir "watchdog.log"

# Ensure logs directory exists
New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logEntry
}

function Test-JupyterRunning {
    # Check for python processes running jupyter
    $jupyterProcesses = Get-Process -Name "python*" -ErrorAction SilentlyContinue | Where-Object {
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            $cmdLine -match "jupyter" -or $cmdLine -match "jupyterlab"
        } catch {
            $false
        }
    }
    
    return ($null -ne $jupyterProcesses -and $jupyterProcesses.Count -gt 0)
}

function Test-JupyterPort {
    param([int]$Port = 8888)
    
    # Load .env to get port if configured
    $envFile = Join-Path $DeployPath ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match "^\s*JUPYTER_PORT\s*=\s*(\d+)") {
                $Port = [int]$matches[1]
            }
        }
    }
    
    # Check if port is listening
    $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    return ($null -ne $connection)
}

function Start-JupyterLab {
    Write-Log "JupyterLab not running - attempting restart..."
    
    $startupTask = "$TaskName-Startup"
    
    # Try to start via the scheduled task
    try {
        Start-ScheduledTask -TaskName $startupTask -ErrorAction Stop
        Write-Log "Started $startupTask task"
        
        # Wait a bit and verify
        Start-Sleep -Seconds 10
        
        if (Test-JupyterPort) {
            Write-Log "JupyterLab restarted successfully (port is listening)"
            return $true
        } else {
            Write-Log "Task started but port not yet listening (may still be starting)"
            return $true
        }
    } catch {
        Write-Log "Failed to start task: $_"
        return $false
    }
}

# Main watchdog logic
Write-Log "Watchdog check started"

$isRunning = Test-JupyterRunning
$portListening = Test-JupyterPort

if ($isRunning -and $portListening) {
    Write-Log "JupyterLab is running and port is listening - all good"
    exit 0
}

if (-not $isRunning) {
    Write-Log "JupyterLab process not found"
    $restarted = Start-JupyterLab
    if (-not $restarted) {
        Write-Log "Failed to restart JupyterLab"
        exit 1
    }
} elseif (-not $portListening) {
    Write-Log "JupyterLab process found but port not listening - may be starting up"
    # Give it some grace time before forcing restart
    exit 0
}

Write-Log "Watchdog check completed"
exit 0
