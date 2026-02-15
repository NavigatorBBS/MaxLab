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

Push-Location $repoRoot
try {
    Write-Output "Configuring nbstripout for this repository..."
    # Use conda run to execute nbstripout in the target environment
    $job = Start-Job -ScriptBlock {
        cd $using:repoRoot
        conda run -n $using:envName nbstripout --install 2>&1
    }
    Wait-Job $job | Out-Null
    Receive-Job $job
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    Write-Output "Nbstripout installed."
} finally {
    Pop-Location
}
