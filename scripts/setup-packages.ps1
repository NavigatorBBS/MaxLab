. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Conda Packages"

$envName = "maxlab"
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

Add-MinicondaToPath
Ensure-CondaAvailable
Enable-CondaInSession
Activate-CondaEnv -EnvName $envName

Write-Information "Installing/updating packages..."
conda install -y @packages
Write-Information "Packages installed/updated (idempotent)."
