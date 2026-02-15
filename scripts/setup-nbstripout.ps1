. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Nbstripout"

$envName = "maxlab"
$repoRoot = Get-RepoRoot
$gitPath = Join-Path $repoRoot ".git"

if (-not (Test-Path $gitPath)) {
    Show-Warning "No .git directory found at $repoRoot. Skipping nbstripout install."
    exit 0
}

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession

Push-Location $repoRoot
try {
    Write-Host -NoNewline "$($Colors.info)⠋ Configuring nbstripout for this repository$($Colors.reset)"
    $job = Start-Job -ScriptBlock {
        cd $using:repoRoot
        conda run -n $using:envName nbstripout --install 2>&1 | Out-Null
    }
    
    $frameIndex = 0
    while ($job.State -eq "Running") {
        $frameIndex = ($frameIndex + 1) % $SpinnerFrames.Count
        Write-Host -NoNewline "`r$($Colors.info)$($SpinnerFrames[$frameIndex]) Configuring nbstripout for this repository$($Colors.reset)"
        Start-Sleep -Milliseconds 100
    }
    
    Wait-Job $job | Out-Null
    Receive-Job $job | Out-Null
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    Write-Host "`r$($Colors.success)✓ Nbstripout installed.$($Colors.reset)                              "
} finally {
    Pop-Location
}
