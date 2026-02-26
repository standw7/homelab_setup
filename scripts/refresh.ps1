# homelab_setup -- Refresh script
# Pulls latest code + images and restarts containers.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Set-Location $ProjectDir

Write-Host "============================================"
Write-Host "  Homelab Refresh"
Write-Host "============================================"
Write-Host ""

# --- Pull latest code ---
Write-Host "Pulling latest code..."
git pull
Write-Host ""

# --- Pull latest container images ---
Write-Host "Pulling latest container images..."
docker compose pull
Write-Host ""

# --- Detect active profiles from running containers ---
$profiles = @()

$running = docker ps --format '{{.Names}}' 2>$null
if ($running) {
    $runningText = $running -join "`n"

    # Check for media profile containers
    if ($runningText -match "strava|spotify|boostcamp") {
        $profiles += "--profile"
        $profiles += "media"
    }

    # Check for automation profile containers
    if ($runningText -match "huginn|n8n") {
        $profiles += "--profile"
        $profiles += "automation"
    }

    # Check for budget profile containers
    if ($runningText -match "actual") {
        $profiles += "--profile"
        $profiles += "budget"
    }
}

if ($profiles.Count -gt 0) {
    Write-Host "Detected active profiles: $($profiles -join ' ')"
}

# --- Restart containers ---
Write-Host ""
Write-Host "Restarting containers..."
& docker compose @profiles up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: docker compose failed (exit code $LASTEXITCODE)."
    exit 1
}

Write-Host ""

# --- Show status ---
Write-Host "============================================"
Write-Host "  Current Status"
Write-Host "============================================"
Write-Host ""
docker compose ps
Write-Host ""
