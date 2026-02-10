. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Pip Packages"

$envName = "maxlab"
$repoRoot = Get-RepoRoot
$pyprojectPath = Join-Path $repoRoot "pyproject.toml"

if (-not (Test-Path $pyprojectPath)) {
    Write-Error "pyproject.toml not found at $pyprojectPath."
    exit 1
}

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession
Enter-CondaEnv -EnvName $envName

Push-Location $repoRoot
try {
    Write-Information "Installing project dependencies (dev + openai + copilot extras)..."
    python -m pip install -e ".[dev,openai,copilot]"
    Write-Information "Pip dependencies installed/updated (idempotent)."
} finally {
    Pop-Location
}
