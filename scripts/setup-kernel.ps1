. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Jupyter Kernel"

$envName = "maxlab"

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession

Write-Host -NoNewline "$($Colors.info)⠋ Registering Jupyter kernel 'MAXLAB'$($Colors.reset)"
$job = Start-Job -ScriptBlock {
    conda run -n $using:envName python -m ipykernel install --user --name $using:envName --display-name "MAXLAB" 2>&1 | Out-Null
}

$frameIndex = 0
while ($job.State -eq "Running") {
    $frameIndex = ($frameIndex + 1) % $SpinnerFrames.Count
    Write-Host -NoNewline "`r$($Colors.info)$($SpinnerFrames[$frameIndex]) Registering Jupyter kernel 'MAXLAB'$($Colors.reset)"
    Start-Sleep -Milliseconds 100
}

Wait-Job $job | Out-Null
Receive-Job $job | Out-Null
Remove-Job $job -Force -ErrorAction SilentlyContinue
Write-Host "`r$($Colors.success)✓ Jupyter kernel registered (idempotent).$($Colors.reset)                              "
