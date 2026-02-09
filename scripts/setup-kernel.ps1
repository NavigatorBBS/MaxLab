. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Jupyter Kernel"

$envName = "maxlab"

Add-MinicondaToPath
Ensure-CondaAvailable
Enable-CondaInSession
Activate-CondaEnv -EnvName $envName

Write-Information "Registering Jupyter kernel 'MAXLAB'..."
python -m ipykernel install --user --name $envName --display-name "MAXLAB"
Write-Information "Jupyter kernel registered (idempotent)."
