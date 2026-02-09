. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Conda Config"

Add-MinicondaToPath
Ensure-CondaAvailable
Enable-CondaInSession
Ensure-CondaChannel
