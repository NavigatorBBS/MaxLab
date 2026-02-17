param (
    [string]$DeployPath = "D:\apps\MaxLab",
    [string]$TaskName = "MaxLabJupyterLab"
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

function Remove-ExistingTasks {
    param([string]$TaskName)
    
    $startupTask = "$TaskName-Startup"
    $watchdogTask = "$TaskName-Watchdog"
    
    Write-Status "Checking for existing scheduled tasks..." "info"
    
    # Remove startup task if exists
    $existing = Get-ScheduledTask -TaskName $startupTask -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Status "Removing existing task: $startupTask" "warning"
        Stop-ScheduledTask -TaskName $startupTask -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $startupTask -Confirm:$false
    }
    
    # Remove watchdog task if exists
    $existing = Get-ScheduledTask -TaskName $watchdogTask -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Status "Removing existing task: $watchdogTask" "warning"
        Stop-ScheduledTask -TaskName $watchdogTask -ErrorAction SilentlyContinue
        Unregister-ScheduledTask -TaskName $watchdogTask -Confirm:$false
    }
    
    Write-Status "Existing tasks cleaned up" "success"
}

function New-StartupTask {
    param([string]$TaskName, [string]$DeployPath)
    
    $startupTask = "$TaskName-Startup"
    $startScript = Join-Path $DeployPath "start.ps1"
    $logsDir = Join-Path $DeployPath "logs" "service"
    
    # Ensure logs directory exists
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    
    Write-Status "Creating startup task: $startupTask" "info"
    
    # Find PowerShell executable (prefer pwsh, fallback to powershell)
    $pwshExe = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwshExe) {
        $psExe = $pwshExe.Source
    } else {
        $psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    }
    
    Write-Status "Using PowerShell: $psExe" "info"
    
    # Create the action - run start.ps1
    $action = New-ScheduledTaskAction `
        -Execute $psExe `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$startScript`"" `
        -WorkingDirectory $DeployPath
    
    # Create trigger - at system startup with 30 second delay
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $trigger.Delay = "PT30S"  # 30 second delay after startup
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartInterval (New-TimeSpan -Minutes 1) `
        -RestartCount 3 `
        -ExecutionTimeLimit (New-TimeSpan -Days 365)
    
    # Create principal - run as SYSTEM with highest privileges
    $principal = New-ScheduledTaskPrincipal `
        -UserId "NT AUTHORITY\SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask `
        -TaskName $startupTask `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Starts MaxLab JupyterLab at system startup" `
        -Force | Out-Null
    
    Write-Status "Startup task created: $startupTask" "success"
}

function New-WatchdogTask {
    param([string]$TaskName, [string]$DeployPath)
    
    $watchdogTask = "$TaskName-Watchdog"
    $watchdogScript = Join-Path $DeployPath "scripts" "watchdog.ps1"
    
    Write-Status "Creating watchdog task: $watchdogTask" "info"
    
    # Find PowerShell executable (prefer pwsh, fallback to powershell)
    $pwshExe = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($pwshExe) {
        $psExe = $pwshExe.Source
    } else {
        $psExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    }
    
    # Create the action - run watchdog.ps1
    $action = New-ScheduledTaskAction `
        -Execute $psExe `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$watchdogScript`" -DeployPath `"$DeployPath`" -TaskName `"$TaskName`"" `
        -WorkingDirectory $DeployPath
    
    # Create trigger - every 5 minutes
    $trigger = New-ScheduledTaskTrigger `
        -Once `
        -At (Get-Date) `
        -RepetitionInterval (New-TimeSpan -Minutes 5)
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
    
    # Create principal - run as SYSTEM with highest privileges
    $principal = New-ScheduledTaskPrincipal `
        -UserId "NT AUTHORITY\SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask `
        -TaskName $watchdogTask `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Monitors MaxLab JupyterLab and restarts if crashed (runs every 5 minutes)" `
        -Force | Out-Null
    
    Write-Status "Watchdog task created: $watchdogTask" "success"
}

function Start-JupyterLabTask {
    param([string]$TaskName)
    
    $startupTask = "$TaskName-Startup"
    
    Write-Status "Starting JupyterLab task..." "info"
    
    Start-ScheduledTask -TaskName $startupTask
    Start-Sleep -Seconds 5
    
    # Check if task started successfully
    $taskInfo = Get-ScheduledTaskInfo -TaskName $startupTask -ErrorAction SilentlyContinue
    if ($taskInfo -and $taskInfo.LastTaskResult -eq 0) {
        Write-Status "JupyterLab task started successfully" "success"
        return $true
    } elseif ($taskInfo -and $taskInfo.LastTaskResult -eq 267009) {
        # 267009 = task is currently running
        Write-Status "JupyterLab task is running" "success"
        return $true
    } else {
        Write-Status "JupyterLab task may still be starting (check logs)" "warning"
        return $true
    }
}

function Start-WatchdogTask {
    param([string]$TaskName)
    
    $watchdogTask = "$TaskName-Watchdog"
    
    Write-Status "Starting watchdog task..." "info"
    
    Start-ScheduledTask -TaskName $watchdogTask
    
    Write-Status "Watchdog task started" "success"
}

# Main execution
Write-Output ""
Write-Status "MaxLab Scheduled Task Setup" "info"
Write-Output "=================================================="
Write-Output ""

# Validate deployment path
if (-not (Test-Path $DeployPath)) {
    Write-Status "Deployment path not found: $DeployPath" "error"
    exit 1
}
Write-Status "Deployment path exists: $DeployPath" "success"

# Validate start.ps1 exists
$startScript = Join-Path $DeployPath "start.ps1"
if (-not (Test-Path $startScript)) {
    Write-Status "Start script not found: $startScript" "error"
    exit 1
}
Write-Status "Start script exists: $startScript" "success"

# Validate watchdog.ps1 exists
$watchdogScript = Join-Path $DeployPath "scripts" "watchdog.ps1"
if (-not (Test-Path $watchdogScript)) {
    Write-Status "Watchdog script not found: $watchdogScript" "error"
    exit 1
}
Write-Status "Watchdog script exists: $watchdogScript" "success"
Write-Output ""

# Remove existing tasks
Remove-ExistingTasks -TaskName $TaskName
Write-Output ""

# Create new tasks
New-StartupTask -TaskName $TaskName -DeployPath $DeployPath
New-WatchdogTask -TaskName $TaskName -DeployPath $DeployPath
Write-Output ""

# Start the tasks
$started = Start-JupyterLabTask -TaskName $TaskName
Start-WatchdogTask -TaskName $TaskName
Write-Output ""

if ($started) {
    Write-Status "Scheduled task setup completed successfully!" "success"
    Write-Status "Task Name: $TaskName" "info"
    Write-Status "Startup Task: $TaskName-Startup" "info"
    Write-Status "Watchdog Task: $TaskName-Watchdog (runs every 5 min)" "info"
    Write-Status "Logs Location: $DeployPath\logs\service\" "info"
    Write-Output ""
    exit 0
} else {
    Write-Status "Tasks created but JupyterLab may not be running yet" "warning"
    Write-Output ""
    exit 1
}
