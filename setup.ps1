$ErrorActionPreference = "Stop"

function Show-BbsHeader {
    param (
        [string]$Title = "NavigatorBBS MaxLab",
        [ConsoleColor]$BorderColor = "Cyan",
        [ConsoleColor]$TitleColor  = "Yellow"
    )

    $padding = 4
    $innerWidth = $Title.Length + ($padding * 2)

    $topBorder    = "╔" + ("═" * $innerWidth) + "╗"
    $bottomBorder = "╚" + ("═" * $innerWidth) + "╝"

    $spaces = " " * $padding
    $line   = "║$spaces$Title$spaces║"

    Write-Host ""
    Write-Host $topBorder    -ForegroundColor $BorderColor
    Write-Host $line         -ForegroundColor $TitleColor
    Write-Host $bottomBorder -ForegroundColor $BorderColor
    Write-Host ""
}
Show-BbsHeader
Show-BbsHeader -Title "Setting up MaxLab Environment"

$envName = "maxlab"
$pythonVersion = "3.12"
$packages = @(
    "jupyterlab",
    "pandas",
    "numpy",
    "scipy",
    "matplotlib",
    "seaborn",
    "scikit-learn",
    "ipykernel",
    "python-dotenv",
    "pre-commit",
    "nbstripout"
)

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
$condaHook = conda "shell.powershell" "hook" 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($condaHook)) {
    Write-Error "Failed to initialize conda for PowerShell. Run 'conda init powershell' and restart the terminal."
    exit 1
}
$condaHookString = $condaHook -join "`n"
. ([scriptblock]::Create($condaHookString))

Write-Output "Configuring conda-forge channel..."
conda config --add channels conda-forge 2>$null
conda config --set channel_priority strict 2>$null
Write-Output "Conda-forge channel configured (idempotent)."

Write-Output "Checking for existing environment '$envName'..."
$envExists = $false
try {
    $envs = conda env list --json | ConvertFrom-Json
    $envExists = $null -ne ($envs.envs | Where-Object { $_ -match "[\\/]${envName}$" })
} catch {
    Write-Error "Error checking conda environments: $_"
    $envExists = $false
}

if (-not $envExists) {
    Write-Output "Creating environment '$envName' with Python $pythonVersion..."
    conda create -y -n $envName "python=$pythonVersion"
    Write-Output "Environment '$envName' created successfully."
} else {
    Write-Output "Environment '$envName' already exists. Skipping creation (idempotent)."
}

Write-Output "Activating environment '$envName'..."
conda activate $envName

Write-Output "Installing/updating packages..."
conda install -y @packages
Write-Output "Packages installed/updated (idempotent)."

Write-Output "Installing Semantic Kernel Python SDK via pip..."
python -m pip install --upgrade "semantic-kernel>=1.39.0" "openai"
Write-Output "Semantic Kernel installed (idempotent)."

Write-Output "Installing MaxLab from pyproject.toml into environment..."
python -m pip install --upgrade pip
python -m pip install -e .
Write-Output "MaxLab installed into environment (idempotent)."

Write-Output "Registering Jupyter kernel 'MAXLAB'..."
python -m ipykernel install --user --name $envName --display-name "MAXLAB"
Write-Output "Jupyter kernel registered (idempotent)."

Write-Output "Setup complete. You can now run './start.ps1' to launch JupyterLab."
