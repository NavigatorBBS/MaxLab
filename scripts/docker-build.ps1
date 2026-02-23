$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$envPath = Join-Path $repoRoot ".env"

$colors = @{
    success = "`e[38;2;76;175;80m"
    error   = "`e[38;2;244;67;54m"
    info    = "`e[38;2;33;150;243m"
    reset   = "`e[0m"
}

Write-Output "$($colors.info)→ Building MaxLab Docker image...$($colors.reset)"

$imageName = "maxlab:latest"

# Check if .env exists and load DOCKER_IMAGE_NAME
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        $line = $_.Trim()
        if ($line -match "^\s*DOCKER_IMAGE_NAME\s*=\s*(.+)\s*$") {
            $imageName = $matches[1].Trim()
            if (($imageName.StartsWith('"') -and $imageName.EndsWith('"')) -or 
                ($imageName.StartsWith("'") -and $imageName.EndsWith("'"))) {
                $imageName = $imageName.Substring(1, $imageName.Length - 2)
            }
        }
    }
}

Write-Output "$($colors.info)→ Image name: $imageName$($colors.reset)"

Push-Location $repoRoot
try {
    docker build -t $imageName .
    if ($LASTEXITCODE -ne 0) {
        Write-Output "$($colors.error)✗ Docker build failed.$($colors.reset)"
        exit 1
    }
    Write-Output "$($colors.success)✓ Docker image built successfully: $imageName$($colors.reset)"
} finally {
    Pop-Location
}
