. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Conda Config"

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession
Set-CondaChannel
