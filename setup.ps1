$ErrorActionPreference = "Stop"

function Show-BbsHeader {
    param (
        [string]$Title = "NavigatorBBS MaxLab Setup"
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
    "python-dotenv"
)

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

Write-Information "Configuring conda-forge channel..."
conda config --add channels conda-forge 2>$null
conda config --set channel_priority strict 2>$null
Write-Information "Conda-forge channel configured (idempotent)."

Write-Information "Checking for existing environment '$envName'..."
$envExists = $false
try {
    $envs = conda env list --json | ConvertFrom-Json
    $envExists = $null -ne ($envs.envs | Where-Object { $_ -match "[\\/]${envName}$" })
} catch {
    Write-Error "Error checking conda environments: $_"
    $envExists = $false
}

if (-not $envExists) {
    Write-Information "Creating environment '$envName' with Python $pythonVersion..."
    conda create -y -n $envName "python=$pythonVersion"
    Write-Information "Environment '$envName' created successfully."
} else {
    Write-Information "Environment '$envName' already exists. Skipping creation (idempotent)."
}

Write-Information "Activating environment '$envName'..."
conda activate $envName

Write-Information "Installing/updating packages..."
conda install -y @packages
Write-Information "Packages installed/updated (idempotent)."

Write-Information "Registering Jupyter kernel 'MAXLAB'..."
python -m ipykernel install --user --name $envName --display-name "MAXLAB" --force
Write-Information "Jupyter kernel registered (idempotent)."

Write-Information "Setup complete. You can now run './start.ps1' to launch JupyterLab."
