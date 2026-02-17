$ErrorActionPreference = "Stop"

# Detect if running in an interactive shell (not CI/GitHub Actions)
$script:IsInteractive = [Environment]::UserInteractive -and -not $env:CI -and -not $env:GITHUB_ACTIONS -and -not $env:TF_BUILD

# Color constants for terminal output
$script:Colors = @{
    success    = "`e[38;2;76;175;80m"     # Green
    error      = "`e[38;2;244;67;54m"     # Red
    warning    = "`e[38;2;255;152;0m"     # Orange/Yellow
    info       = "`e[38;2;33;150;243m"    # Blue
    accent     = "`e[38;2;80;200;200m"    # Teal
    gold       = "`e[38;2;230;200;120m"   # Gold
    reset      = "`e[0m"
    dim        = "`e[2m"
}

# Spinner animation frames
$script:SpinnerFrames = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
$script:SpinnerIndex = 0

function Show-Spinner {
    param(
        [string]$Message,
        [scriptblock]$ScriptBlock = $null,
        [int]$Timeout = 300
    )
    
    if ($null -eq $ScriptBlock) {
        Write-Output "$($script:Colors.info)→ $Message$($script:Colors.reset)"
        return
    }
    
    # In non-interactive mode (CI), show static message without spinner animation
    if (-not $script:IsInteractive) {
        Write-Output "$($script:Colors.info)→ $Message...$($script:Colors.reset)"
        $job = Start-Job -ScriptBlock $ScriptBlock
        Wait-Job $job -Timeout $Timeout | Out-Null
        $result = Receive-Job $job
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        Write-Output "$($script:Colors.success)✓ $Message$($script:Colors.reset)"
        return $result
    }
    
    # Interactive mode: show animated spinner
    Write-Host -NoNewline "$($script:Colors.info)$($script:SpinnerFrames[0]) $Message$($script:Colors.reset)" -ForegroundColor Blue
    
    $job = Start-Job -ScriptBlock $ScriptBlock
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $frameIndex = 0
    
    while ($job.State -eq "Running") {
        if ($stopwatch.Elapsed.TotalSeconds -gt $Timeout) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Write-Host "`r$($script:Colors.warning)⏱ Timeout - took too long$($script:Colors.reset)                              "
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            return $null
        }
        
        Start-Sleep -Milliseconds 100
        $frameIndex = ($frameIndex + 1) % $script:SpinnerFrames.Count
        Write-Host -NoNewline "`r$($script:Colors.info)$($script:SpinnerFrames[$frameIndex]) $Message$($script:Colors.reset)" -ForegroundColor Blue
    }
    
    # Job completed
    $result = Receive-Job $job
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    Write-Host "`r$($script:Colors.success)✓ $Message$($script:Colors.reset)                              "
    return $result
}

function Show-Success {
    param([string]$Message)
    Write-Output "$($script:Colors.success)✓ $Message$($script:Colors.reset)"
}

function Show-Warning {
    param([string]$Message)
    Write-Output "$($script:Colors.warning)⚠ $Message$($script:Colors.reset)"
}

function Show-Error {
    param([string]$Message)
    Write-Output "$($script:Colors.error)✗ $Message$($script:Colors.reset)"
}

function Show-Step {
    param([string]$Message)
    Write-Output "$($script:Colors.accent)→ $Message$($script:Colors.reset)"
}

function Show-BbsHeader {
    param (
        [string]$Title
    )

    $padding = 4
    $width = $Title.Length + ($padding * 2)

    $border = "+" + ("-" * $width) + "+"
    $spaces = " " * $padding
    $line = "|$spaces$Title$spaces|"

    Write-Output ""
    Write-Output "$($script:Colors.accent)$border$($script:Colors.reset)"
    Write-Output "$($script:Colors.accent)$line$($script:Colors.reset)"
    Write-Output "$($script:Colors.accent)$border$($script:Colors.reset)"
    Write-Output ""
}

function Get-RepoRoot {
    $scriptsDir = $null
    if ($PSScriptRoot) {
        $scriptsDir = $PSScriptRoot
    } elseif ($PSCommandPath) {
        $scriptsDir = Split-Path -Parent $PSCommandPath
    } elseif ($MyInvocation.MyCommand.Path) {
        $scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    if (-not $scriptsDir) {
        Write-Error "Unable to determine scripts directory for repo root resolution."
        exit 1
    }

    return (Resolve-Path (Join-Path $scriptsDir ".."))
}

function Add-MinicondaToPath {
    $minicondaPath = "$env:USERPROFILE\miniconda3"
    $minicondaScriptsPath = "$minicondaPath\Scripts"
    if ((Test-Path $minicondaPath) -and ($env:PATH -notlike "*$minicondaScriptsPath*")) {
        $env:PATH = "$minicondaScriptsPath;$minicondaPath;$env:PATH"
        Write-Output "Added Miniconda to PATH: $minicondaPath"
    }
}

function Invoke-Conda {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [object[]]$Args
    )
    try {
        $cmd = (Get-Command conda -ErrorAction Stop).Source
    } catch {
        Write-Error "Conda executable not found. Ensure conda is on PATH."
        exit 1
    }
    & $cmd @Args
}

function Test-CondaAvailable {
    if (-not (Get-Command conda -ErrorAction SilentlyContinue)) {
        Write-Error "Conda is not available in this session. Install Miniconda and ensure conda is on PATH."
        exit 1
    }
}

function Enable-CondaInSession {
    Show-Step "Initializing conda for PowerShell session..."
    try {
        # Get conda root - use CONDA_ROOT if available, otherwise derive from CONDA_EXE or use default
        $condaRoot = $env:CONDA_ROOT
        if (-not $condaRoot -and $env:CONDA_EXE) {
            # CONDA_EXE is like C:\path\Scripts\conda.exe, so go up two levels
            $condaRoot = Split-Path -Parent (Split-Path -Parent $env:CONDA_EXE)
        }
        if (-not $condaRoot) {
            $condaRoot = "$env:USERPROFILE\miniconda3"
        }
        
        Write-Output "  $($script:Colors.info)Conda root: $condaRoot$($script:Colors.reset)"
        if ($condaRoot -and (Test-Path $condaRoot)) {
            $modulePath = Join-Path $condaRoot "shell\condabin\Conda.psm1"
            if (Test-Path $modulePath) {
                Write-Output "  $($script:Colors.info)→ Loading Conda PowerShell module...$($script:Colors.reset)"
                Import-Module $modulePath -ErrorAction SilentlyContinue
            }
        }
        Show-Success "Conda initialized successfully."
    } catch {
        Show-Error "Failed to initialize conda for PowerShell: $_"
        Write-Output "  $($script:Colors.warning)Ensure 'conda init powershell' has been run.$($script:Colors.reset)"
        exit 1
    }
}

function Set-CondaChannel {
    Show-Step "Configuring conda-forge channel..."
    
    # In non-interactive mode (CI), show static message without spinner animation
    if (-not $script:IsInteractive) {
        Write-Output "$($script:Colors.info)→ Setting conda-forge channel...$($script:Colors.reset)"
        
        $job1 = Start-Job -ScriptBlock { conda config --add channels conda-forge 2>$null }
        $job2 = Start-Job -ScriptBlock { conda config --set channel_priority strict 2>$null }
        
        Wait-Job $job1 -Timeout 30 | Out-Null
        Wait-Job $job2 -Timeout 30 | Out-Null
        
        Remove-Job $job1 -Force -ErrorAction SilentlyContinue
        Remove-Job $job2 -Force -ErrorAction SilentlyContinue
        
        Write-Output "$($script:Colors.success)✓ Conda-forge channel configured (idempotent).$($script:Colors.reset)"
        return
    }
    
    # Interactive mode: show animated spinner
    Write-Host -NoNewline "$($script:Colors.info)⠋ Setting conda-forge channel$($script:Colors.reset)"
    
    # Run in background with timeout as a workaround for hanging issue
    $job1 = Start-Job -ScriptBlock { conda config --add channels conda-forge 2>$null }
    $job2 = Start-Job -ScriptBlock { conda config --set channel_priority strict 2>$null }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $frameIndex = 0
    
    while (($job1.State -eq "Running" -or $job2.State -eq "Running") -and $stopwatch.Elapsed.TotalSeconds -lt 30) {
        $frameIndex = ($frameIndex + 1) % $script:SpinnerFrames.Count
        Write-Host -NoNewline "`r$($script:Colors.info)$($script:SpinnerFrames[$frameIndex]) Setting conda-forge channel$($script:Colors.reset)"
        Start-Sleep -Milliseconds 100
    }
    
    Wait-Job $job1 -Timeout 10 | Out-Null
    Wait-Job $job2 -Timeout 10 | Out-Null
    
    Remove-Job $job1 -Force -ErrorAction SilentlyContinue
    Remove-Job $job2 -Force -ErrorAction SilentlyContinue
    
    Write-Host "`r$($script:Colors.success)✓ Conda-forge channel configured (idempotent).$($script:Colors.reset)                              "
}

function Test-CondaEnvironment {
    param (
        [string]$EnvName
    )

    $envExists = $false
    try {
        # Use background job with timeout to avoid hanging
        $job = Start-Job -ScriptBlock { conda env list 2>$null }
        Wait-Job $job -Timeout 10 | Out-Null
        $envOutput = Receive-Job $job
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        
        $envExists = $null -ne ($envOutput | Where-Object { $_ -match "[\\/]${EnvName}(\s|$)" })
    } catch {
        Show-Warning "Error checking conda environments: $_"
        $envExists = $false
    }
    return $envExists
}

function New-CondaEnvironment {
    param (
        [string]$EnvName,
        [string]$PythonVersion
    )

    Show-Step "Checking for existing environment '$EnvName'..."
    $envExists = Test-CondaEnvironment -EnvName $EnvName

    if (-not $envExists) {
        # In non-interactive mode (CI), show static message without spinner animation
        if (-not $script:IsInteractive) {
            Write-Output "$($script:Colors.info)→ Creating environment '$EnvName' with Python $PythonVersion (this may take a few minutes)...$($script:Colors.reset)"
            
            $job = Start-Job -ScriptBlock {
                conda create -y -n $using:EnvName "python=$using:PythonVersion" 2>&1 | Out-Null
            }
            
            Wait-Job $job -Timeout 600 | Out-Null
            Receive-Job $job | Out-Null
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            
            Write-Output "$($script:Colors.success)✓ Environment '$EnvName' created successfully.$($script:Colors.reset)"
            return
        }
        
        # Interactive mode: show animated spinner
        Write-Host -NoNewline "$($script:Colors.info)⠋ Creating environment '$EnvName' with Python $PythonVersion (this may take a few minutes)$($script:Colors.reset)"
        
        # Use background job to avoid hanging on conda create
        $job = Start-Job -ScriptBlock {
            conda create -y -n $using:EnvName "python=$using:PythonVersion" 2>&1 | Out-Null
        }
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $frameIndex = 0
        
        while ($job.State -eq "Running" -and $stopwatch.Elapsed.TotalSeconds -lt 600) {
            $frameIndex = ($frameIndex + 1) % $script:SpinnerFrames.Count
            Write-Host -NoNewline "`r$($script:Colors.info)$($script:SpinnerFrames[$frameIndex]) Creating environment '$EnvName' with Python $PythonVersion (this may take a few minutes)$($script:Colors.reset)"
            Start-Sleep -Milliseconds 100
        }
        
        Wait-Job $job | Out-Null
        Receive-Job $job | Out-Null
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        Write-Host "`r$($script:Colors.success)✓ Environment '$EnvName' created successfully.$($script:Colors.reset)                              "
    } else {
        Show-Success "Environment '$EnvName' already exists. Skipping creation (idempotent)."
    }
}

function Enter-CondaEnv {
    param (
        [string]$EnvName
    )

    Write-Output "Activating environment '$EnvName'..."
    # Set environment variables to activate conda environment
    $condaRoot = $env:CONDA_PREFIX
    if (-not $condaRoot) {
        $condaRoot = "$env:USERPROFILE\miniconda3"
    }
    
    $envPath = Join-Path $condaRoot "envs" $EnvName
    if (Test-Path $envPath) {
        # Set up environment variables for the activated environment
        $env:CONDA_PREFIX = $envPath
        $env:CONDA_DEFAULT_ENV = $EnvName
        # Add environment paths
        $env:PATH = "$envPath;$envPath\Library\mingw-w64\bin;$envPath\Library\usr\bin;$envPath\Library\bin;$envPath\Scripts;$env:PATH"
    } else {
        Write-Error "Environment '$EnvName' not found at $envPath"
        exit 1
    }
}
