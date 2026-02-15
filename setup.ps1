param (
    [string[]]$Steps,
    [switch]$ListSteps
)

$ErrorActionPreference = "Stop"

function Show-BigLogo {
    $reset = "`e[0m"

    $gold   = "`e[38;2;230;200;120m"
    $yellow = "`e[38;2;220;230;180m"
    $teal   = "`e[38;2;80;200;200m"

    Write-Host "$gold███╗   ██╗ █████╗ ██╗   ██╗██╗ ██████╗  █████╗ ████████╗ ██████╗ ██████╗$reset"
    Write-Host "$yellow████╗  ██║██╔══██╗██║   ██║██║██╔════╝ ██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗$reset"
    Write-Host "$yellow██╔██╗ ██║███████║██║   ██║██║██║  ███╗███████║   ██║   ██║   ██║██████╔╝$reset"
    Write-Host "$teal██║╚██╗██║██╔══██║╚██╗ ██╔╝██║██║   ██║██╔══██║   ██║   ██║   ██║██╔══██╗$reset"
    Write-Host "$teal██║ ╚████║██║  ██║ ╚████╔╝ ██║╚██████╔╝██║  ██║   ██║   ╚██████╔╝██║  ██║$reset"
    Write-Host "$teal╚═╝  ╚═══╝╚═╝  ╚═╝  ╚═══╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝$reset"

    $reset = "`e[0m"
    $teal  = "`e[38;2;80;200;200m"

    Write-Host ""
    Write-Host "$teal        ══▶   ██████╗ ██████╗ ███████╗   ◀══$reset"
    Write-Host "$teal              ██╔══██╗██╔══██╗██╔════╝$reset"
    Write-Host "$teal              ██████╔╝██████╔╝███████╗$reset"
    Write-Host "$teal              ██╔══██╗██╔══██╗╚════██║$reset"
    Write-Host "$teal              ██████╔╝██████╔╝███████║$reset"
    Write-Host ""
    Start-Sleep -Milliseconds 150
    Write-Host "`e[2mNavigator BBS Environment Ready`e[0m"
}

function Show-BbsHeader {
    param (
        [string]$Title = "NavigatorBBS MaxLab Setup"
    )

    $padding = 4
    $width   = $Title.Length + ($padding * 2)

    $border  = "+" + ("-" * $width) + "+"
    $spaces  = " " * $padding
    $line    = "|$spaces$Title$spaces|"

    Write-Output ""
    Write-Output $border
    Write-Output $line
    Write-Output $border
    Write-Output ""
}

Show-BigLogo
Show-BbsHeader -Title "Setting up MaxLab Environment"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptsDir = Join-Path $repoRoot "scripts"

$availableSteps = [ordered]@{
    "envfile" = @{ Script = "setup-envfile.ps1"; Description = "Create .env from .env.example if missing" }
    "conda" = @{ Script = "setup-conda.ps1"; Description = "Configure conda-forge channel" }
    "env" = @{ Script = "setup-env.ps1"; Description = "Create the maxlab conda environment" }
    "packages" = @{ Script = "setup-packages.ps1"; Description = "Install conda packages" }
    "kernel" = @{ Script = "setup-kernel.ps1"; Description = "Register Jupyter kernel" }
    "precommit" = @{ Script = "setup-precommit.ps1"; Description = "Install pre-commit hooks" }
    "nbstripout" = @{ Script = "setup-nbstripout.ps1"; Description = "Configure nbstripout" }
}

if ($ListSteps) {
    Write-Output "Available setup steps:"
    foreach ($step in $availableSteps.Keys) {
        $desc = $availableSteps[$step].Description
        Write-Output "  $($teal)▸ $step$($reset): $desc"
    }
    exit 0
}

if (-not $Steps -or $Steps.Count -eq 0) {
    $Steps = $availableSteps.Keys
}

$Steps = $Steps | ForEach-Object { $_.ToLowerInvariant() }

$teal = "`e[38;2;80;200;200m"
$reset = "`e[0m"
$green = "`e[38;2;76;175;80m"

foreach ($step in $Steps) {
    if (-not $availableSteps.Contains($step)) {
        Write-Error "Unknown step '$step'. Run ./setup.ps1 -ListSteps for valid options."
        exit 1
    }

    $scriptName = $availableSteps[$step].Script
    $scriptPath = Join-Path $scriptsDir $scriptName
    if (-not (Test-Path $scriptPath)) {
        Write-Error "Missing script for step '$step' at $scriptPath."
        exit 1
    }

    Write-Output "$($teal)→ Running step '$step'...$($reset)"
    & $scriptPath
}

Write-Output ""
Write-Output "$($green)✓ Setup complete. You can now run './start.ps1' to launch JupyterLab.$($reset)"
