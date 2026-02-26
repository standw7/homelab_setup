#!/usr/bin/env bash
# Install Docker Engine + Docker Compose plugin
set -euo pipefail

if command -v docker &>/dev/null; then
    echo "Docker is already installed: $(docker --version)"
    if docker compose version &>/dev/null; then
        echo "Docker Compose plugin: $(docker compose version)"
    else
        echo "WARNING: Docker Compose plugin not found. Please install it."
    fi
    exit 0
fi

echo "Installing Docker..."

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
else
    echo "ERROR: Cannot detect Linux distribution."
    exit 1
fi

case "$DISTRO" in
    ubuntu|debian|linuxmint|pop)
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    fedora)
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sudo systemctl enable docker
        ;;
    arch|manjaro|endeavouros)
        sudo pacman -Syu --noconfirm docker docker-compose docker-buildx
        sudo systemctl start docker
        sudo systemctl enable docker
        ;;
    *)
        echo "ERROR: Unsupported distribution '$DISTRO'."
        echo "Please install Docker manually: https://docs.docker.com/engine/install/"
        exit 1
        ;;
esac

# Add current user to docker group
if ! groups "$USER" | grep -q '\bdocker\b'; then
    sudo usermod -aG docker "$USER"
    echo ""
    echo "NOTE: You were added to the 'docker' group."
    echo "You may need to log out and back in for this to take effect."
fi

echo ""
echo "Docker installed successfully!"
docker --version
docker compose version
