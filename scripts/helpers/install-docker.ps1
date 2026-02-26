# Install Docker Desktop for Windows
$ErrorActionPreference = "Stop"

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Docker is already installed: $(docker --version)"
    if (docker compose version 2>$null) {
        Write-Host "Docker Compose: $(docker compose version)"
    }
    return
}

Write-Host "Installing Docker Desktop..."

# Check WSL2
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "WSL2 is required for Docker Desktop."
    Write-Host "Installing WSL..."
    wsl --install --no-distribution
    Write-Host ""
    Write-Host "WSL installed. You may need to restart your computer."
    Write-Host "After restarting, run this setup script again."
    exit 1
}

# Install via winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Installing Docker Desktop via winget..."
    winget install -e --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
} else {
    Write-Host "ERROR: winget not found."
    Write-Host "Please install Docker Desktop manually from:"
    Write-Host "  https://www.docker.com/products/docker-desktop/"
    exit 1
}

Write-Host ""
Write-Host "Docker Desktop installed."
Write-Host "Please start Docker Desktop and wait for it to finish initializing."
Write-Host "Then re-run this setup script."
