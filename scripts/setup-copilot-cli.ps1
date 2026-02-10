. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - GitHub Copilot CLI"

$copilotCommand = Get-Command copilot -ErrorAction SilentlyContinue
if ($copilotCommand) {
    $copilotVersion = copilot --version
    Write-Information "GitHub Copilot CLI already installed: $copilotVersion"
    Write-Information "Manual authentication required: run 'copilot auth login' if not already configured."
    exit 0
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm is not available. Install Node.js first (setup-nodejs.ps1)."
    exit 1
}

Write-Information "Installing GitHub Copilot CLI via npm..."
npm install -g @githubnext/github-copilot-cli

$copilotCommand = Get-Command copilot -ErrorAction SilentlyContinue
if (-not $copilotCommand) {
    Write-Error "GitHub Copilot CLI was installed, but 'copilot' is not available on PATH. Restart your terminal and try again."
    exit 1
}

Write-Information "GitHub Copilot CLI version: $(copilot --version)"
Write-Information "Manual authentication required: run 'copilot auth login'."
