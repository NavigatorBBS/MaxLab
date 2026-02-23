$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$colors = @{
    success = "`e[38;2;76;175;80m"
    error   = "`e[38;2;244;67;54m"
    info    = "`e[38;2;33;150;243m"
    reset   = "`e[0m"
}

Write-Output "$($colors.info)→ Starting MaxLab container with docker compose...$($colors.reset)"

Push-Location $repoRoot
try {
    docker compose up --build
    if ($LASTEXITCODE -ne 0) {
        Write-Output "$($colors.error)✗ Failed to start container.$($colors.reset)"
        exit 1
    }
} finally {
    Pop-Location
}
