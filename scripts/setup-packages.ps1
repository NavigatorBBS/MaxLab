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
    "python-dotenv",
    "pre-commit",
    "nbstripout"
)

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession

Write-Output "Installing/updating packages in '$envName' environment..."
# Use conda run to execute install in the target environment without activation
$job = Start-Job -ScriptBlock {
    conda run -n $using:envName conda install -y $using:packages 2>&1 | Out-Null
}
Wait-Job $job | Out-Null
Receive-Job $job
Remove-Job $job -Force -ErrorAction SilentlyContinue
Write-Output "Packages installed/updated (idempotent)."
