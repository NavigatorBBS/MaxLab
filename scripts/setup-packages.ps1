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

Write-Host -NoNewline "$($Colors.info)⠋ Installing/updating packages in '$envName' environment (this may take a few minutes)$($Colors.reset)"
$job = Start-Job -ScriptBlock {
    conda run -n $using:envName conda install -y $using:packages 2>&1 | Out-Null
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$frameIndex = 0

while ($job.State -eq "Running" -and $stopwatch.Elapsed.TotalSeconds -lt 600) {
    $frameIndex = ($frameIndex + 1) % $SpinnerFrames.Count
    Write-Host -NoNewline "`r$($Colors.info)$($SpinnerFrames[$frameIndex]) Installing/updating packages in '$envName' environment (this may take a few minutes)$($Colors.reset)"
    Start-Sleep -Milliseconds 100
}

Wait-Job $job | Out-Null
Receive-Job $job | Out-Null
Remove-Job $job -Force -ErrorAction SilentlyContinue
Write-Host "`r$($Colors.success)✓ Packages installed/updated (idempotent).$($Colors.reset)                              "
