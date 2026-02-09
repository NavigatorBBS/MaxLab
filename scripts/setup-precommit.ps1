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
Ensure-CondaAvailable
Enable-CondaInSession
Activate-CondaEnv -EnvName $envName

Push-Location $repoRoot
try {
    Write-Information "Installing pre-commit hooks..."
    pre-commit install
    Write-Information "Pre-commit hooks installed."
} finally {
    Pop-Location
}
