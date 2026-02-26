#!/usr/bin/env bash
# homelab_setup — Linux bootstrap script
# Installs dependencies, configures environment, and starts the homelab stack.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "============================================"
echo "  Homelab Setup — Linux Bootstrap"
echo "============================================"
echo ""

# --- Check if running as root ---
if [ "$(id -u)" -eq 0 ]; then
    echo "WARNING: Running as root is not recommended."
    echo "This script will use 'sudo' when needed."
    echo ""
fi

# --- Check/install Git ---
if ! command -v git &>/dev/null; then
    echo "Git not found. Installing..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y git
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y git
    elif command -v pacman &>/dev/null; then
        sudo pacman -Syu --noconfirm git
    else
        echo "ERROR: Cannot install Git automatically. Please install it manually."
        exit 1
    fi
fi
echo "Git: $(git --version)"

# --- Check/install Docker ---
if ! command -v docker &>/dev/null; then
    echo ""
    echo "Docker not found. Installing..."
    bash "$SCRIPT_DIR/helpers/install-docker.sh"
else
    echo "Docker: $(docker --version)"
fi

if ! docker compose version &>/dev/null; then
    echo "ERROR: Docker Compose plugin not found. Please install it."
    exit 1
fi

# --- Check/install Tailscale ---
if ! command -v tailscale &>/dev/null; then
    echo ""
    echo "Tailscale not found. Installing..."
    bash "$SCRIPT_DIR/helpers/install-tailscale.sh"
fi

# --- Get Tailscale IP ---
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
if [ -z "$TAILSCALE_IP" ]; then
    echo ""
    echo "ERROR: Cannot detect Tailscale IP."
    echo "Please make sure Tailscale is connected (run: sudo tailscale up)"
    exit 1
fi
echo "Tailscale IP: $TAILSCALE_IP"

# --- Create .env if it doesn't exist ---
if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo ""
    echo "Creating .env from .env.example..."
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
fi

# --- Set Tailscale IP in .env ---
sed -i "s/^TAILSCALE_IP=.*/TAILSCALE_IP=$TAILSCALE_IP/" "$PROJECT_DIR/.env"
echo "Set TAILSCALE_IP=$TAILSCALE_IP in .env"

# --- Template CoreDNS Corefile ---
if grep -q "TAILSCALE_IP_PLACEHOLDER" "$PROJECT_DIR/coredns/Corefile"; then
    sed -i "s/TAILSCALE_IP_PLACEHOLDER/$TAILSCALE_IP/g" "$PROJECT_DIR/coredns/Corefile"
    echo "Updated CoreDNS Corefile with Tailscale IP"
fi

# --- Helper: set env var in .env file ---
set_env() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" "$PROJECT_DIR/.env"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$PROJECT_DIR/.env"
    else
        echo "${key}=${value}" >> "$PROJECT_DIR/.env"
    fi
}

# --- Helper: prompt for env var ---
prompt_env() {
    local key="$1"
    local description="$2"
    local current
    current=$(grep "^${key}=" "$PROJECT_DIR/.env" | cut -d'=' -f2- || true)

    if [ -n "$current" ]; then
        echo "  $key is already set (keeping existing value)"
        return
    fi

    echo ""
    echo "  $description"
    read -rp "  $key: " value
    if [ -n "$value" ]; then
        set_env "$key" "$value"
    fi
}

# --- Helper: auto-generate secret ---
generate_secret() {
    local key="$1"
    local current
    current=$(grep "^${key}=" "$PROJECT_DIR/.env" | cut -d'=' -f2- || true)

    if [ -n "$current" ]; then
        echo "  $key is already set (keeping existing value)"
        return
    fi

    local secret
    secret=$(openssl rand -hex 32)
    set_env "$key" "$secret"
    echo "  $key: auto-generated"
}

echo ""
echo "============================================"
echo "  Configure Environment Variables"
echo "============================================"
echo ""
echo "Required variables (press Enter to skip optional ones):"

# --- Required ---
prompt_env "TELEGRAM_TOKEN" "Bot token from @BotFather on Telegram"
prompt_env "ANTHROPIC_API_KEY" "API key from https://console.anthropic.com/settings/keys"
prompt_env "ALLOWED_CHAT_IDS" "Comma-separated Telegram chat IDs (your chat ID)"

# --- Auto-generate secrets ---
echo ""
echo "Auto-generating secrets..."
generate_secret "DOIT_SECRET_KEY"
generate_secret "MACRONOTION_SECRET_KEY"
generate_secret "DOIT_INTERNAL_API_KEY"
generate_secret "SIRI_API_KEY"

# --- Optional ---
echo ""
echo "Optional variables (press Enter to skip):"
prompt_env "DOIT_GOOGLE_CLIENT_ID" "Google OAuth Client ID (for calendar sync in DoIt)"
prompt_env "DOIT_GOOGLE_CLIENT_SECRET" "Google OAuth Client Secret"
prompt_env "MACRONOTION_NOTION_CLIENT_ID" "Notion OAuth Client ID (from notion.so/my-integrations)"
prompt_env "MACRONOTION_NOTION_CLIENT_SECRET" "Notion OAuth Client Secret"
prompt_env "GOOGLE_ICAL_URLS" "Google Calendar iCal URLs (pipe-separated)"

echo ""
echo "Optional profiles (media, automation, budget):"
prompt_env "STRAVA_CLIENT_ID" "Strava API Client ID (profile: media)"
prompt_env "STRAVA_CLIENT_SECRET" "Strava API Client Secret (profile: media)"
prompt_env "YOUR_SPOTIFY_PUBLIC" "Spotify App Client ID (profile: media)"
prompt_env "YOUR_SPOTIFY_SECRET" "Spotify App Client Secret (profile: media)"

# --- Start the stack ---
echo ""
echo "============================================"
echo "  Starting Homelab"
echo "============================================"
echo ""

# Determine which profiles to enable based on configured env vars
PROFILES=""
source "$PROJECT_DIR/.env"

if [ -n "${STRAVA_CLIENT_ID:-}" ] || [ -n "${YOUR_SPOTIFY_PUBLIC:-}" ]; then
    PROFILES="$PROFILES --profile media"
fi
if [ -n "${HUGINN_APP_SECRET_TOKEN:-}" ]; then
    PROFILES="$PROFILES --profile automation"
fi

echo "Starting core services..."
# shellcheck disable=SC2086
docker compose $PROFILES up -d

echo ""
echo "============================================"
echo "  Homelab is running!"
echo "============================================"
echo ""
echo "  Dashboard:  http://home.homelab"
echo "  Tasks:      http://tasks.homelab"
echo "  Meals:      http://meals.homelab"
echo "  Habits:     http://habits.homelab"
echo "  Fitness:    http://fitness.homelab"
echo "  Docker:     http://docker.homelab"
echo ""
echo "  IMPORTANT: Configure your Tailscale DNS to use"
echo "  this machine as a DNS server for the 'homelab' domain."
echo "  See docs/tailscale.md for instructions."
echo ""
