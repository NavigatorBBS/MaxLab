param (
    [int]$Port
)

$ErrorActionPreference = "Stop"

function Show-BigLogo {
    $reset = "`e[0m"

    $gold   = "`e[38;2;230;200;120m"
    $yellow = "`e[38;2;220;230;180m"
    $teal   = "`e[38;2;80;200;200m"

    Write-Host "$gold███╗   ██╗ █████╗ ██╗   ██╗██╗ ██████╗  █████╗ ████████╗ ██████╗ ██████╗$reset"
    Write-Host "$yellow████╗  ██║██╔══██╗██║   ██║██║██╔════╝ ██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗$reset"
    Write-Host "$yellow██╔██╗ ██║███████║██║   ██║██║██║  ███╗███████║   ██║   ██║   ██║██████╔╝$reset"
    Write-Host "$teal██║╚██╗██║██╔══██║╚██╗ ██╔╝██║██║   ██║██╔══██║   ██║   ██║   ██║██╔══██╗$reset"
    Write-Host "$teal██║ ╚████║██║  ██║ ╚████╔╝ ██║╚██████╔╝██║  ██║   ██║   ╚██████╔╝██║  ██║$reset"
    Write-Host "$teal╚═╝  ╚═══╝╚═╝  ╚═╝  ╚═══╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝$reset"

    $reset = "`e[0m"
    $teal  = "`e[38;2;80;200;200m"

    Write-Host ""
    Write-Host "$teal        ══▶   ██████╗ ██████╗ ███████╗   ◀══$reset"
    Write-Host "$teal              ██╔══██╗██╔══██╗██╔════╝$reset"
    Write-Host "$teal              ██████╔╝██████╔╝███████╗$reset"
    Write-Host "$teal              ██╔══██╗██╔══██╗╚════██║$reset"
    Write-Host "$teal              ██████╔╝██████╔╝███████║$reset"
    Write-Host ""
    Start-Sleep -Milliseconds 150
    Write-Host "`e[2mNavigator BBS Environment Ready`e[0m"
}

function Show-BbsHeader {
    param (
        [string]$Title = "NavigatorBBS MaxLab Startup"
    )

    $padding = 4
    $width   = $Title.Length + ($padding * 2)

    $border  = "+" + ("-" * $width) + "+"
    $spaces  = " " * $padding
    $line    = "|$spaces$Title$spaces|"

    Write-Output ""
    Write-Output $border
    Write-Output $line
    Write-Output $border
    Write-Output ""
}

function Import-DotEnv {
    param (
        [string]$Path
    )

    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) {
            return
        }

        if ($line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$") {
            $name = $matches[1]
            $value = $matches[2].Trim()
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }

            $existing = Get-Item -Path "Env:$name" -ErrorAction SilentlyContinue
            if ($null -eq $existing -or [string]::IsNullOrWhiteSpace($existing.Value)) {
                Set-Item -Path "Env:$name" -Value $value
            }
        }
    }
}

Show-BigLogo
Show-BbsHeader -Title "Starting JupyterLab in MaxLab Environment"

$envName = "maxlab"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path $repoRoot ".env"
$envExamplePath = Join-Path $repoRoot ".env.example"

if (Test-Path $envPath) {
    Import-DotEnv -Path $envPath
} elseif (Test-Path $envExamplePath) {
    Write-Output "No .env found. Run ./setup.ps1 or copy .env.example to .env for defaults."
}

$notebookDir = if ($env:JUPYTER_NOTEBOOK_DIR) { $env:JUPYTER_NOTEBOOK_DIR } else { "workspace" }
$resolvedPort = $null

if ($PSBoundParameters.ContainsKey("Port")) {
    $resolvedPort = $Port
} elseif ($env:JUPYTER_PORT) {
    $parsed = 0
    if ([int]::TryParse($env:JUPYTER_PORT, [ref]$parsed)) {
        $resolvedPort = $parsed
    } else {
        Write-Warning "JUPYTER_PORT is not a valid integer. Falling back to 8888."
        $resolvedPort = 8888
    }
} else {
    $resolvedPort = 8888
}

if ([string]::IsNullOrWhiteSpace($notebookDir)) {
    $notebookDir = "workspace"
}

$notebookDirPath = $notebookDir
if (-not [System.IO.Path]::IsPathRooted($notebookDirPath)) {
    $notebookDirPath = Join-Path $repoRoot $notebookDirPath
}

# Add Miniconda to PATH if not already present
$minicondaPath = "$env:USERPROFILE\miniconda3"
$minicondaScriptsPath = "$minicondaPath\Scripts"
if ((Test-Path $minicondaPath) -and ($env:PATH -notlike "*$minicondaScriptsPath*")) {
    $env:PATH = "$minicondaScriptsPath;$minicondaPath;$env:PATH"
    Write-Output "Added Miniconda to PATH: $minicondaPath"
}

if (-not (Get-Command conda -ErrorAction SilentlyContinue)) {
    Write-Error "Conda is not available in this session. Install Miniconda and ensure conda is on PATH."
    exit 1
}

# Enable conda in the current PowerShell session
$condaRoot = $env:CONDA_ROOT
if (-not $condaRoot -and $env:CONDA_EXE) {
    $condaRoot = Split-Path -Parent (Split-Path -Parent $env:CONDA_EXE)
}
if (-not $condaRoot) {
    $condaRoot = "$env:USERPROFILE\miniconda3"
}

$modulePath = Join-Path $condaRoot "shell\condabin\Conda.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -ErrorAction SilentlyContinue
} else {
    Write-Error "Failed to initialize conda for PowerShell. Conda module not found at $modulePath"
    exit 1
}

# Check if notebook directory exists
if (-not (Test-Path $notebookDirPath)) {
    Write-Error "Notebook directory '$notebookDirPath' not found. Please run from the maxlab repository root."
    exit 1
}

Write-Output "Activating environment '$envName'..."
# Set conda environment variables to activate the environment
$env:CONDA_PREFIX = Join-Path $minicondaPath "envs" $envName
$env:CONDA_DEFAULT_ENV = $envName
$env:PATH = "$(Join-Path $env:CONDA_PREFIX 'Scripts');$(Join-Path $env:CONDA_PREFIX 'Library\mingw-w64\bin');$(Join-Path $env:CONDA_PREFIX 'Library\usr\bin');$(Join-Path $env:CONDA_PREFIX 'Library\bin');$env:PATH"

# Check if port is already in use
try {
    $netstat = netstat -ano | Select-String ":$resolvedPort "
    if ($netstat) {
        Write-Warning "Port $resolvedPort is already in use. You can specify a different port: ./start.ps1 -Port 9000"
    }
} catch {
    Write-Verbose "Port availability check failed: $_"
}

Write-Output "Starting JupyterLab on port $resolvedPort with notebook dir '$notebookDirPath'..."
jupyter lab --port $resolvedPort --notebook-dir $notebookDirPath
