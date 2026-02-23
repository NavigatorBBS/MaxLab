$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$envPath = Join-Path $repoRoot ".env"

$colors = @{
    success = "`e[38;2;76;175;80m"
    error   = "`e[38;2;244;67;54m"
    warning = "`e[38;2;255;152;0m"
    info    = "`e[38;2;33;150;243m"
    reset   = "`e[0m"
}

# Load environment variables from .env
$dockerhubUsername = $null
$dockerhubToken = $null
$dockerRepository = "maxlab"
$customTag = "latest"

if (-not (Test-Path $envPath)) {
    Write-Output "$($colors.error)✗ .env file not found. Copy .env.example to .env and configure Docker Hub credentials.$($colors.reset)"
    exit 1
}

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
            "DOCKERHUB_USERNAME" { $script:dockerhubUsername = $value }
            "DOCKERHUB_TOKEN" { $script:dockerhubToken = $value }
            "DOCKER_REPOSITORY" { $script:dockerRepository = $value }
            "DOCKER_TAG" { $script:customTag = $value }
        }
    }
}

# Validate required variables
if (-not $dockerhubUsername -or $dockerhubUsername -eq "your-dockerhub-username") {
    Write-Output "$($colors.error)✗ DOCKERHUB_USERNAME not configured in .env$($colors.reset)"
    exit 1
}

if (-not $dockerhubToken -or $dockerhubToken -eq "your-dockerhub-access-token") {
    Write-Output "$($colors.error)✗ DOCKERHUB_TOKEN not configured in .env$($colors.reset)"
    Write-Output "  Create an access token at: https://hub.docker.com/settings/security"
    exit 1
}

if (-not $dockerRepository -or $dockerRepository -eq "your-dockerhub-repository") {
    Write-Output "$($colors.error)✗ DOCKER_REPOSITORY not configured in .env$($colors.reset)"
    exit 1
}

if (-not $customTag) {
    $customTag = "latest"
}

$imageBase = "$dockerhubUsername/$dockerRepository"
$tags = @("latest")
if ($customTag -ne "latest") {
    $tags += $customTag
}

Write-Output "$($colors.info)→ Logging in to Docker Hub as '$dockerhubUsername'...$($colors.reset)"
$dockerhubToken | docker login -u $dockerhubUsername --password-stdin
if ($LASTEXITCODE -ne 0) {
    Write-Output "$($colors.error)✗ Docker Hub login failed.$($colors.reset)"
    exit 1
}
Write-Output "$($colors.success)✓ Logged in to Docker Hub.$($colors.reset)"

Write-Output "$($colors.info)→ Building image: $imageBase with tags [$($tags -join ', ')]...$($colors.reset)"
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

    Write-Output "$($colors.success)✓ Image built successfully.$($colors.reset)"

    Write-Output "$($colors.info)→ Pushing image to Docker Hub...$($colors.reset)"
    foreach ($tag in $tags) {
        $fullImage = "${imageBase}:${tag}"
        docker push $fullImage
        if ($LASTEXITCODE -ne 0) {
            Write-Output "$($colors.error)✗ Docker push failed: $fullImage$($colors.reset)"
            exit 1
        }
    }
    Write-Output "$($colors.success)✓ Image pushed to Docker Hub: ${imageBase}:latest$($colors.reset)"
    if ($tags.Count -gt 1) {
        Write-Output "$($colors.success)✓ Additional image pushed: ${imageBase}:$customTag$($colors.reset)"
    }
} finally {
    Pop-Location
    docker logout
}
