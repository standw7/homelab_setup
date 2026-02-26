#!/usr/bin/env bash
# Install Tailscale and authenticate
set -euo pipefail

if command -v tailscale &>/dev/null; then
    echo "Tailscale is already installed."
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
    if [ -n "$TAILSCALE_IP" ]; then
        echo "Tailscale IP: $TAILSCALE_IP"
    else
        echo "Tailscale is installed but not connected."
        echo "Please run: sudo tailscale up"
    fi
    exit 0
fi

echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

echo ""
echo "Tailscale installed. Starting authentication..."
echo "A browser window will open for you to sign in."
echo ""
sudo tailscale up

TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
if [ -n "$TAILSCALE_IP" ]; then
    echo ""
    echo "Tailscale connected! Your IP: $TAILSCALE_IP"
else
    echo ""
    echo "WARNING: Could not detect Tailscale IP."
    echo "Please run 'sudo tailscale up' manually and then re-run setup."
fi
