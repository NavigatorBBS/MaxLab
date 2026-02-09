. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Node.js"

$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCommand) {
    $nodeVersion = node --version
    Write-Information "Node.js already installed: $nodeVersion"
    exit 0
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is not available. Install Microsoft App Installer from the Microsoft Store and try again."
    exit 1
}

Write-Information "Installing Node.js via winget..."
winget install --id OpenJS.NodeJS -e --accept-package-agreements --accept-source-agreements

$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCommand) {
    Write-Error "Node.js was installed, but 'node' is not available on PATH. Restart your terminal and try again."
    exit 1
}

Write-Information "Node.js version: $(node --version)"
Write-Information "npm version: $(npm --version)"
