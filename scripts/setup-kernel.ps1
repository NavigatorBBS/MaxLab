. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Jupyter Kernel"

$envName = "maxlab"

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession

Write-Output "Registering Jupyter kernel 'MAXLAB'..."
# Use conda run to execute python command in the target environment
$job = Start-Job -ScriptBlock {
    conda run -n $using:envName python -m ipykernel install --user --name $using:envName --display-name "MAXLAB" 2>&1
}
Wait-Job $job | Out-Null
Receive-Job $job
Remove-Job $job -Force -ErrorAction SilentlyContinue
Write-Output "Jupyter kernel registered (idempotent)."
