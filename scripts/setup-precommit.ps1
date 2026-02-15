. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Pre-commit"

$envName = "maxlab"
$repoRoot = Get-RepoRoot
$gitPath = Join-Path $repoRoot ".git"

if (-not (Test-Path $gitPath)) {
    Write-Warning "No .git directory found at $repoRoot. Skipping pre-commit install."
    exit 0
}

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession

Push-Location $repoRoot
try {
    Write-Output "Installing pre-commit hooks..."
    # Use conda run to execute pre-commit in the target environment
    $job = Start-Job -ScriptBlock {
        cd $using:repoRoot
        conda run -n $using:envName pre-commit install 2>&1
    }
    Wait-Job $job | Out-Null
    Receive-Job $job
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    Write-Output "Pre-commit hooks installed."
} finally {
    Pop-Location
}
