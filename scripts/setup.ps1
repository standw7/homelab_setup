# homelab_setup -- Windows bootstrap script
# Installs dependencies, configures environment, and starts the homelab stack.
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

Set-Location $ProjectDir

Write-Host "============================================"
Write-Host "  Homelab Setup - Windows Bootstrap"
Write-Host "============================================"
Write-Host ""

# --- Check/install Git ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git not found. Installing..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
        $env:PATH = "$env:PATH;C:\Program Files\Git\cmd"
    } else {
        Write-Host "ERROR: Cannot install Git. Please install manually from https://git-scm.com/"
        exit 1
    }
}
Write-Host "Git: $(git --version)"

# --- Check/install Docker ---
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "Docker not found. Installing..."
    & "$ScriptDir\helpers\install-docker.ps1"
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: Docker still not available. Please restart and re-run."
        exit 1
    }
}
Write-Host "Docker: $(docker --version)"

# --- Check/install Tailscale ---
if (-not (Get-Command tailscale -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "Tailscale not found. Installing..."
    & "$ScriptDir\helpers\install-tailscale.ps1"
}

# --- Get Tailscale IP ---
$TailscaleIP = $null
try {
    $TailscaleIP = (tailscale ip -4 2>$null).Trim()
} catch {}

if (-not $TailscaleIP) {
    Write-Host ""
    Write-Host "ERROR: Cannot detect Tailscale IP."
    Write-Host "Please make sure Tailscale is connected and signed in."
    exit 1
}
Write-Host "Tailscale IP: $TailscaleIP"

# --- Create .env if it doesn't exist ---
$EnvFile = Join-Path $ProjectDir ".env"
$EnvExample = Join-Path $ProjectDir ".env.example"

if (-not (Test-Path $EnvFile)) {
    Write-Host ""
    Write-Host "Creating .env from .env.example..."
    Copy-Item $EnvExample $EnvFile
}

# --- Helper: read .env into hashtable ---
function Read-EnvFile {
    $envVars = @{}
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $envVars[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    return $envVars
}

# --- Helper: set env var in .env ---
function Set-EnvVar {
    param([string]$Key, [string]$Value)
    $content = Get-Content $EnvFile -Raw
    if ($content -match ('(?m)^' + $Key + '=')) {
        $content = $content -replace ('(?m)^' + $Key + '=.*'), ($Key + '=' + $Value)
    } else {
        $content += "`n${Key}=${Value}"
    }
    Set-Content $EnvFile $content -NoNewline
}

# --- Helper: prompt for env var ---
function Prompt-EnvVar {
    param([string]$Key, [string]$Description)
    $envVars = Read-EnvFile
    if ($envVars[$Key]) {
        Write-Host "  $Key is already set - keeping existing value"
        return
    }
    Write-Host ""
    Write-Host "  $Description"
    $value = Read-Host "  $Key"
    if ($value) {
        Set-EnvVar -Key $Key -Value $value
    }
}

# --- Helper: generate secret ---
function Generate-Secret {
    param([string]$Key)
    $envVars = Read-EnvFile
    if ($envVars[$Key]) {
        Write-Host "  $Key is already set - keeping existing value"
        return
    }
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $bytes = New-Object byte[] 32
    $rng.GetBytes($bytes)
    $rng.Dispose()
    $secret = ([BitConverter]::ToString($bytes) -replace '-', '').ToLower()
    Set-EnvVar -Key $Key -Value $secret
    Write-Host "  ${Key}: auto-generated"
}

# --- Set Tailscale IP ---
Set-EnvVar -Key "TAILSCALE_IP" -Value $TailscaleIP
Write-Host "Set TAILSCALE_IP=$TailscaleIP in .env"

# --- Template CoreDNS Corefile ---
$CoreFile = Join-Path $ProjectDir "coredns\Corefile"
if (Test-Path $CoreFile) {
    $coreContent = Get-Content $CoreFile -Raw
    if ($coreContent -match "TAILSCALE_IP_PLACEHOLDER") {
        $coreContent = $coreContent -replace "TAILSCALE_IP_PLACEHOLDER", $TailscaleIP
        Set-Content $CoreFile $coreContent -NoNewline
        Write-Host "Updated CoreDNS Corefile with Tailscale IP"
    }
}

Write-Host ""
Write-Host "============================================"
Write-Host "  Configure Environment Variables"
Write-Host "============================================"
Write-Host ""
Write-Host 'Required variables (press Enter to skip optional ones):'

# --- Required ---
Prompt-EnvVar -Key "TELEGRAM_TOKEN" -Description "Bot token from @BotFather on Telegram"
Prompt-EnvVar -Key "ANTHROPIC_API_KEY" -Description "API key from https://console.anthropic.com/settings/keys"
Prompt-EnvVar -Key "ALLOWED_CHAT_IDS" -Description 'Comma-separated Telegram chat IDs - your chat ID'

# --- Auto-generate secrets ---
Write-Host ""
Write-Host "Auto-generating secrets..."
Generate-Secret -Key "DOIT_SECRET_KEY"
Generate-Secret -Key "MACRONOTION_SECRET_KEY"
Generate-Secret -Key "DOIT_INTERNAL_API_KEY"
Generate-Secret -Key "SIRI_API_KEY"

# --- Optional ---
Write-Host ""
Write-Host 'Optional variables (press Enter to skip):'
Prompt-EnvVar -Key "DOIT_GOOGLE_CLIENT_ID" -Description 'Google OAuth Client ID - for calendar sync in DoIt'
Prompt-EnvVar -Key "DOIT_GOOGLE_CLIENT_SECRET" -Description "Google OAuth Client Secret"
Prompt-EnvVar -Key "MACRONOTION_NOTION_CLIENT_ID" -Description 'Notion OAuth Client ID - from notion.so/my-integrations'
Prompt-EnvVar -Key "MACRONOTION_NOTION_CLIENT_SECRET" -Description "Notion OAuth Client Secret"
Prompt-EnvVar -Key "GOOGLE_ICAL_URLS" -Description 'Google Calendar iCal URLs - pipe-separated'

Write-Host ""
Write-Host 'Optional profiles (media, automation, budget):'
Prompt-EnvVar -Key "STRAVA_CLIENT_ID" -Description 'Strava API Client ID - profile: media'
Prompt-EnvVar -Key "STRAVA_CLIENT_SECRET" -Description 'Strava API Client Secret - profile: media'
Prompt-EnvVar -Key "YOUR_SPOTIFY_PUBLIC" -Description 'Spotify App Client ID - profile: media'
Prompt-EnvVar -Key "YOUR_SPOTIFY_SECRET" -Description 'Spotify App Client Secret - profile: media'

# --- Start the stack ---
Write-Host ""
Write-Host "============================================"
Write-Host "  Starting Homelab"
Write-Host "============================================"
Write-Host ""

# Determine profiles based on configured env vars
$envVars = Read-EnvFile
$profiles = @()

if ($envVars["STRAVA_CLIENT_ID"] -or $envVars["YOUR_SPOTIFY_PUBLIC"]) {
    $profiles += "--profile"
    $profiles += "media"
}
if ($envVars["HUGINN_APP_SECRET_TOKEN"]) {
    $profiles += "--profile"
    $profiles += "automation"
}

Write-Host "Starting core services..."
& docker compose @profiles up -d

Write-Host ""
Write-Host "============================================"
Write-Host "  Homelab is running!"
Write-Host "============================================"
Write-Host ""
Write-Host "  Dashboard:  http://home.homelab"
Write-Host "  Tasks:      http://tasks.homelab"
Write-Host "  Meals:      http://meals.homelab"
Write-Host "  Habits:     http://habits.homelab"
Write-Host "  Fitness:    http://fitness.homelab"
Write-Host "  Docker:     http://docker.homelab"
Write-Host ""
Write-Host "  IMPORTANT: Configure your Tailscale DNS to use"
Write-Host "  this machine as a DNS server for the 'homelab' domain."
Write-Host "  See docs/tailscale.md for instructions."
Write-Host ""
