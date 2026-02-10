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

    Write-Information ""
    Write-Information $border
    Write-Information $line
    Write-Information $border
    Write-Information ""
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
        Write-Information "Added Miniconda to PATH: $minicondaPath"
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
    $condaHook = Invoke-Conda "shell.powershell" "hook" 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($condaHook)) {
        Write-Error "Failed to initialize conda for PowerShell. Run 'conda init powershell' and restart the terminal."
        exit 1
    }
    $condaHookString = $condaHook -join "`n"
    . ([scriptblock]::Create($condaHookString))
}

function Set-CondaChannel {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    Write-Information "Configuring conda-forge channel..."
    if ($PSCmdlet.ShouldProcess('conda','Add conda-forge channel')) { Invoke-Conda -Command 'config' -Arguments '--add', 'channels', 'conda-forge' 2>$null }
    if ($PSCmdlet.ShouldProcess('conda','Set channel priority to strict')) { Invoke-Conda -Command 'config' -Arguments '--set', 'channel_priority', 'strict' 2>$null }
    Write-Information "Conda-forge channel configured (idempotent)."
}

function Test-CondaEnvironment {
    param (
        [string]$EnvName
    )

    $envExists = $false
    try {
        $envs = Invoke-Conda -Command 'env' -Arguments 'list', '--json' | ConvertFrom-Json
        $envExists = $null -ne ($envs.envs | Where-Object { $_ -match "[\\/]${EnvName}$" })
    } catch {
        Write-Error "Error checking conda environments: $_"
        $envExists = $false
    }
    return $envExists
}

function New-CondaEnvironment {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [string]$EnvName,
        [string]$PythonVersion
    )

    Write-Information "Checking for existing environment '$EnvName'..."
    $envExists = Test-CondaEnvironment -EnvName $EnvName

    if (-not $envExists) {
        Write-Information "Creating environment '$EnvName' with Python $PythonVersion..."
        if ($PSCmdlet.ShouldProcess("conda","Create environment $EnvName")) { Invoke-Conda create -y -n $EnvName "python=$PythonVersion" }
        Write-Information "Environment '$EnvName' created successfully."
    } else {
        Write-Information "Environment '$EnvName' already exists. Skipping creation (idempotent)."
    }
}

function Enter-CondaEnv {
    param (
        [string]$EnvName
    )

    Write-Information "Activating environment '$EnvName'..."
    Invoke-Conda activate $EnvName
}
