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

$dockerhubUsername = "local"
$dockerRepository = "maxlab"
$customTag = "latest"

# Check if .env exists and load Docker image variables
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) { return }

        if ($line -match "^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)\s*$") {
            $name = $matches[1]
            $value = $matches[2].Trim()
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }

            switch ($name) {
                "DOCKERHUB_USERNAME" {
                    if ($value -and $value -ne "your-dockerhub-username") {
                        $script:dockerhubUsername = $value
                    }
                }
                "DOCKER_REPOSITORY" {
                    if ($value) {
                        $script:dockerRepository = $value
                    }
                }
                "DOCKER_TAG" {
                    if ($value) {
                        $script:customTag = $value
                    }
                }
            }
        }
    }
}

$imageBase = "$dockerhubUsername/$dockerRepository"
$tags = @("latest")
if ($customTag -and $customTag -ne "latest") {
    $tags += $customTag
}

Write-Output "$($colors.info)→ Image base: $imageBase$($colors.reset)"
Write-Output "$($colors.info)→ Tags: $($tags -join ', ')$($colors.reset)"

Push-Location $repoRoot
try {
    $primaryImage = "${imageBase}:latest"
    docker build -t $primaryImage .
    if ($LASTEXITCODE -ne 0) {
        Write-Output "$($colors.error)✗ Docker build failed.$($colors.reset)"
        exit 1
    }

    foreach ($tag in $tags) {
        if ($tag -eq "latest") { continue }
        $taggedImage = "${imageBase}:${tag}"
        docker tag $primaryImage $taggedImage
        if ($LASTEXITCODE -ne 0) {
            Write-Output "$($colors.error)✗ Failed to create tag: $taggedImage$($colors.reset)"
            exit 1
        }
    }

    Write-Output "$($colors.success)✓ Docker image built successfully: ${imageBase}:latest$($colors.reset)"
    if ($tags.Count -gt 1) {
        Write-Output "$($colors.success)✓ Additional tag created: ${imageBase}:$customTag$($colors.reset)"
    }
} finally {
    Pop-Location
}
