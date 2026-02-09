. "$(Join-Path $PSScriptRoot "common.ps1")"

Show-BbsHeader -Title "MaxLab Setup - Conda Env"

$envName = "maxlab"
$pythonVersion = "3.12"

Add-MinicondaToPath
Ensure-CondaAvailable
Enable-CondaInSession
Ensure-CondaEnv -EnvName $envName -PythonVersion $pythonVersion
