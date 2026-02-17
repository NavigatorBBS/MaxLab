#!/usr/bin/env powershell
<#
.SYNOPSIS
    Validates that the Windows server is ready for MaxLab deployment.
    
.DESCRIPTION
    Checks all required dependencies and configurations for successful deployment:
    - Git installation
    - Conda installation (searches standard paths)
    - maxlab conda environment (created by setup.ps1)
    - Directory permissions
    - Network connectivity
    - Disk space
    - Tailscale installation
    - Tailscale auth secrets
    
.EXAMPLE
    .\validate-deployment-ready.ps1
    
.NOTES
    Run this on your Windows server runner before attempting deployments.
#>

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

function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction SilentlyContinue
        return $?
    } catch {
        return $false
    }
}

function Find-CondaPath {
    # Search common conda installation locations
    $search_paths = @(
        "C:\Program Files\Miniconda3\Scripts\conda.exe",
        "C:\Program Files\Miniconda3",
        "C:\Miniconda3\Scripts\conda.exe",
        "C:\Miniconda3",
        "$env:USERPROFILE\Miniconda3\Scripts\conda.exe",
        "$env:USERPROFILE\Miniconda3",
        "$env:USERPROFILE\AppData\Local\Miniconda3\Scripts\conda.exe",
        "$env:USERPROFILE\AppData\Local\Miniconda3"
    )
    
    foreach ($path in $search_paths) {
        # Check for conda.exe directly
        if ($path -like "*.exe" -and (Test-Path $path)) {
            return $path
        }
        # Check for conda in Scripts subdirectory
        if (-not ($path -like "*.exe")) {
            $conda_exe = Join-Path $path "Scripts\conda.exe"
            if (Test-Path $conda_exe) {
                return $conda_exe
            }
        }
    }
    
    return $null
}

Write-Output ""
Write-Status "MaxLab Deployment Readiness Check" "info"
Write-Output "=================================================="
Write-Output ""

$checks_passed = 0
$checks_failed = 0
$issues = @()
$conda_path = $null

# Check 1: Git Installation
Write-Output "Checking Git installation..."
if (Test-Command "git") {
    $git_version = & git --version
    Write-Status "$git_version" "success"
    $checks_passed++
} else {
    Write-Status "Git not found" "error"
    $checks_failed++
    $issues += "Git Installation: Run: choco install git"
}

# Check 2: Conda Installation (search standard paths)
Write-Output "Checking Conda installation..."
$conda_path = Find-CondaPath
if ($conda_path) {
    Write-Status "Conda found at: $conda_path" "success"
    $checks_passed++
    
    # Check 3: maxlab environment
    Write-Output "Checking maxlab conda environment..."
    try {
        $env_exists = & "$conda_path" env list 2>&1 | Select-String "maxlab"
        if ($env_exists) {
            Write-Status "maxlab environment exists" "success"
            $checks_passed++
        } else {
            Write-Status "maxlab environment not found" "error"
            $checks_failed++
            $issues += "Conda Environment: Run on server: .\setup.ps1"
        }
    } catch {
        Write-Status "maxlab environment not found" "error"
        $checks_failed++
        $issues += "Conda Environment: Run on server: .\setup.ps1"
    }
} else {
    Write-Status "Conda not found in standard locations" "error"
    $checks_failed += 2
    $issues += "Conda Installation: Install Miniconda3 from https://docs.conda.io/projects/miniconda/en/latest/ or download from https://repo.anaconda.com/miniconda/"
}

# Check 4: Directory permissions
Write-Output "Checking deployment directory permissions..."
$deploy_dirs = @("D:\apps\MaxLab", "D:\apps\MaxLabTest")
$perms_ok = $true

foreach ($dir in $deploy_dirs) {
    $parent = Split-Path $dir -Parent
    if (Test-Path $parent) {
        try {
            $test_file = Join-Path $parent ".write_test_$(Get-Random)"
            New-Item -Path $test_file -ItemType File -Force -ErrorAction Stop | Out-Null
            Remove-Item $test_file -Force -ErrorAction Stop | Out-Null
            Write-Status "$parent is writable" "success"
        } catch {
            Write-Status "Cannot write to $parent" "error"
            $perms_ok = $false
        }
    } else {
        Write-Status "Parent directory doesn't exist: $parent (will be created)" "warning"
    }
}

if ($perms_ok) {
    $checks_passed++
} else {
    $checks_failed++
    $issues += "Directory Permissions: Ensure user running runner has write access to D:\apps\"
}

# Check 5: Network connectivity
Write-Output "Checking network connectivity..."
try {
    $test = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($test.StatusCode -eq 200) {
        Write-Status "Can reach GitHub (needed for git clone)" "success"
        $checks_passed++
    } else {
        throw "Bad status code"
    }
} catch {
    Write-Status "Cannot reach GitHub" "error"
    $checks_failed++
    $issues += "Network Connectivity: Ensure server has internet access to github.com"
}

# Check 6: Disk space
Write-Output "Checking disk space..."
$disk = Get-Volume -DriveLetter D -ErrorAction SilentlyContinue
if ($disk) {
    $free_gb = [math]::Round($disk.SizeRemaining / 1GB, 2)
    if ($disk.SizeRemaining -gt 10GB) {
        Write-Status "D: drive has $free_gb GB free" "success"
        $checks_passed++
    } else {
        Write-Status "D: drive has only $free_gb GB free (recommend 10+ GB)" "warning"
        $issues += "Disk Space: Consider freeing up space or using different drive"
    }
} else {
    Write-Status "Could not check disk space" "warning"
}

# Check 7: GitHub Actions runner
Write-Output "Checking GitHub Actions runner..."
$runner_process = Get-Process -Name "Runner.Listener" -ErrorAction SilentlyContinue
if ($runner_process) {
    Write-Status "GitHub Actions runner is running (PID: $($runner_process.Id))" "success"
    $checks_passed++
} else {
    Write-Status "GitHub Actions runner not detected (might not be started)" "warning"
    $issues += "Runner Status: Start GitHub Actions runner service if deployments should be automatic"
}

# Check 8: Port availability
Write-Output "Checking port availability..."
$ports = @(8888, 8889)
$ports_ok = $true

foreach ($port in $ports) {
    try {
        $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($connection) {
            Write-Status "Port $port is already in use" "warning"
            $ports_ok = $false
        } else {
            Write-Status "Port $port is available" "success"
        }
    } catch {
        Write-Status "Port $port is available" "success"
    }
}

if ($ports_ok) {
    $checks_passed++
} else {
    $checks_failed++
    $issues += "Port Availability: Kill existing processes using ports 8888/8889 or configure different ports in .env"
}

# Check 9: Tailscale Installation
Write-Output "Checking Tailscale installation..."
if (Test-Command "tailscale.exe") {
    try {
        $tailscale_status = & tailscale.exe status 2>&1
        Write-Status "Tailscale installed and responding" "success"
        $checks_passed++
    } catch {
        Write-Status "Tailscale installed but not responding" "warning"
        $checks_failed++
        $issues += "Tailscale Status: Run: tailscale login (or restart Tailscale service)"
    }
} else {
    Write-Status "Tailscale not found in PATH" "error"
    $checks_failed++
    $issues += "Tailscale Installation: Run: choco install tailscale OR download from https://tailscale.com/download"
}

# Check 10: Tailscale auth secrets in GitHub Actions
Write-Output "Checking Tailscale auth secrets configuration..."
$env_token = $env:TAILSCALE_AUTHKEY
if ($env_token) {
    Write-Status "Tailscale secrets appear to be configured in GitHub Actions" "success"
    $checks_passed++
} else {
    Write-Status "Tailscale secrets not found in current environment" "warning"
    $issues += "Tailscale Secrets: Add TAILSCALE_AUTHKEY to GitHub repo Settings Secrets Actions (production and test environments)"
}

# Summary
Write-Output ""
Write-Output "=================================================="
Write-Output "VALIDATION SUMMARY"
Write-Output "=================================================="
Write-Status "Passed: $checks_passed" "success"
if ($checks_failed -gt 0) {
    Write-Status "Failed: $checks_failed" "error"
}
Write-Output ""

if ($issues.Count -gt 0) {
    Write-Status "ISSUES TO RESOLVE:" "warning"
    Write-Output ""
    foreach ($issue in $issues) {
        Write-Output "  - $issue"
    }
    Write-Output ""
    Write-Status "After fixing issues, run this script again to verify." "info"
    exit 1
} else {
    Write-Output ""
    Write-Status "All checks passed! Server is ready for deployment." "success"
    Write-Output ""
    Write-Status "Next steps:" "info"
    Write-Output "  1. Push to main or test branch"
    Write-Output "  2. Monitor: GitHub Actions -> Deploy MaxLab"
    Write-Output "  3. Verify: Get-Service MaxLabJupyterLab (or MaxLabJupyterLabTest)"
    Write-Output ""
    exit 0
}
