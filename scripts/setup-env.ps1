. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Conda Env"

$envName = "maxlab"
$pythonVersion = "3.12"

Add-MinicondaToPath
Test-CondaAvailable
Enable-CondaInSession
New-CondaEnvironment -EnvName $envName -PythonVersion $pythonVersion
