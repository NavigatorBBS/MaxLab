. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - .env"

$repoRoot = Get-RepoRoot
$envPath = Join-Path $repoRoot ".env"
$envExamplePath = Join-Path $repoRoot ".env.example"

if (Test-Path $envPath) {
    Write-Information "Found existing .env at $envPath. Skipping creation."
    exit 0
}

if (-not (Test-Path $envExamplePath)) {
    Write-Warning "No .env.example found at $envExamplePath. Skipping .env creation."
    exit 0
}

Copy-Item $envExamplePath $envPath
Write-Information "Created .env from .env.example at $envPath."
