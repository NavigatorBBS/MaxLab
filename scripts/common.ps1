$ErrorActionPreference = "Stop"

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
    Write-Output $border
    Write-Output $line
    Write-Output $border
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
    Write-Output "Initializing conda for PowerShell session..."
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
        
        Write-Output "Conda root: $condaRoot"
        if ($condaRoot -and (Test-Path $condaRoot)) {
            $modulePath = Join-Path $condaRoot "shell\condabin\Conda.psm1"
            if (Test-Path $modulePath) {
                Write-Output "Loading Conda PowerShell module from $modulePath..."
                Import-Module $modulePath -ErrorAction SilentlyContinue
            }
        }
        Write-Output "Conda initialized successfully."
    } catch {
        Write-Error "Failed to initialize conda for PowerShell: $_`nEnsure 'conda init powershell' has been run."
        exit 1
    }
}

function Set-CondaChannel {
    Write-Output "Configuring conda-forge channel..."
    # Run in background with timeout as a workaround for hanging issue
    $job1 = Start-Job -ScriptBlock { conda config --add channels conda-forge 2>$null }
    $job2 = Start-Job -ScriptBlock { conda config --set channel_priority strict 2>$null }
    
    Wait-Job $job1 -Timeout 10 | Out-Null
    Wait-Job $job2 -Timeout 10 | Out-Null
    
    Remove-Job $job1 -Force -ErrorAction SilentlyContinue
    Remove-Job $job2 -Force -ErrorAction SilentlyContinue
    
    Write-Output "Conda-forge channel configured (idempotent)."
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
        Write-Output "Error checking conda environments: $_"
        $envExists = $false
    }
    return $envExists
}

function New-CondaEnvironment {
    param (
        [string]$EnvName,
        [string]$PythonVersion
    )

    Write-Output "Checking for existing environment '$EnvName'..."
    $envExists = Test-CondaEnvironment -EnvName $EnvName

    if (-not $envExists) {
        Write-Output "Creating environment '$EnvName' with Python $PythonVersion..."
        # Use background job to avoid hanging on conda create
        $job = Start-Job -ScriptBlock {
            conda create -y -n $using:EnvName "python=$using:PythonVersion" 2>&1 | Out-Null
        }
        Write-Output "This may take a few minutes..."
        Wait-Job $job | Out-Null
        $jobResult = Receive-Job $job
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        Write-Output "Environment '$EnvName' created successfully."
    } else {
        Write-Output "Environment '$EnvName' already exists. Skipping creation (idempotent)."
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
