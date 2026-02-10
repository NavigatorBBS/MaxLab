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
Test-CondaAvailable
Enable-CondaInSession
Enter-CondaEnv -EnvName $envName

Write-Information "Installing/updating packages..."
Invoke-Conda install -y @packages
Write-Information "Packages installed/updated (idempotent)."
