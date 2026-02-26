#!/usr/bin/env bash
# homelab_setup — Refresh script
# Pulls latest code + images and restarts containers.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "============================================"
echo "  Homelab Refresh"
echo "============================================"
echo ""

# --- Pull latest code ---
echo "Pulling latest code..."
git pull
echo ""

# --- Pull latest container images ---
echo "Pulling latest container images..."
docker compose pull
echo ""

# --- Detect active profiles from running containers ---
PROFILES=""

running=$(docker ps --format '{{.Names}}' 2>/dev/null || true)

# Check for media profile containers
if echo "$running" | grep -qE "strava|spotify|boostcamp"; then
    PROFILES="$PROFILES --profile media"
fi

# Check for automation profile containers
if echo "$running" | grep -qE "huginn|n8n"; then
    PROFILES="$PROFILES --profile automation"
fi

# Check for budget profile containers
if echo "$running" | grep -qE "actual"; then
    PROFILES="$PROFILES --profile budget"
fi

if [ -n "$PROFILES" ]; then
    echo "Detected active profiles:$PROFILES"
fi

# --- Restart containers ---
echo ""
echo "Restarting containers..."
# shellcheck disable=SC2086
docker compose $PROFILES up -d
echo ""

# --- Show status ---
echo "============================================"
echo "  Current Status"
echo "============================================"
echo ""
docker compose ps
echo ""
