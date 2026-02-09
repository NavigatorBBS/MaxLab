param (
    [int]$Port = 8888
)

$ErrorActionPreference = "Stop"

function Show-BbsHeader {
    param (
        [string]$Title = "NavigatorBBS MaxLab Startup"
    )

    $padding = 4
    $width   = $Title.Length + ($padding * 2)

    $border  = "+" + ("-" * $width) + "+"
    $spaces  = " " * $padding
    $line    = "|$spaces$Title$spaces|"

    Write-Information ""
    Write-Information $border
    Write-Information $line
    Write-Information $border
    Write-Information ""
}
Show-BbsHeader
Show-BbsHeader -Title "Starting JupyterLab in MaxLab Environment"

$envName = "maxlab"
$notebookDir = "workspace"

# Add Miniconda to PATH if not already present
$minicondaPath = "$env:USERPROFILE\miniconda3"
$minicondaScriptsPath = "$minicondaPath\Scripts"
if ((Test-Path $minicondaPath) -and ($env:PATH -notlike "*$minicondaScriptsPath*")) {
    $env:PATH = "$minicondaScriptsPath;$minicondaPath;$env:PATH"
    Write-Information "Added Miniconda to PATH: $minicondaPath"
}

if (-not (Get-Command conda -ErrorAction SilentlyContinue)) {
    Write-Error "Conda is not available in this session. Install Miniconda and ensure conda is on PATH."
    exit 1
}

# Enable conda in the current PowerShell session
$condaHook = conda "shell.powershell" "hook" 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($condaHook)) {
    Write-Error "Failed to initialize conda for PowerShell. Run 'conda init powershell' and restart the terminal."
    exit 1
}
$condaHookString = $condaHook -join "`n"
. ([scriptblock]::Create($condaHookString))

# Check if notebook directory exists
if (-not (Test-Path $notebookDir)) {
    Write-Error "Notebook directory '$notebookDir' not found. Please run from the maxlab repository root."
    exit 1
}

Write-Information "Activating environment '$envName'..."
conda activate $envName

# Check if port is already in use
try {
    $netstat = netstat -ano | Select-String ":$Port "
    if ($netstat) {
        Write-Warning "Port $Port is already in use. You can specify a different port: ./start.ps1 -Port 9000"
    }
} catch {
    Write-Verbose "Port availability check failed: $_"
}

Write-Information "Starting JupyterLab on port $Port with notebook dir '$notebookDir'..."
jupyter lab --port $Port --notebook-dir $notebookDir
