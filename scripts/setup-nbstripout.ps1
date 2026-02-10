. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Nbstripout"

$envName = "maxlab"
$repoRoot = Get-RepoRoot
$gitPath = Join-Path $repoRoot ".git"

if (-not (Test-Path $gitPath)) {
    Write-Warning "No .git directory found at $repoRoot. Skipping nbstripout install."
    exit 0
}

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession
Enter-CondaEnv -EnvName $envName

Push-Location $repoRoot
try {
    Write-Information "Configuring nbstripout for this repository..."
    nbstripout --install
    Write-Information "Nbstripout installed."
} finally {
    Pop-Location
}
