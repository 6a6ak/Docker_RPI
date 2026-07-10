#!/usr/bin/env bash

set -e

USER_NAME="$(whoami)"

echo "[1] Detect OS..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "Cannot detect OS."
    exit 1
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="${VERSION_CODENAME}"

if [ "$ARCH" != "arm64" ]; then
    echo "This script is recommended for 64-bit Raspberry Pi OS or Ubuntu ARM64."
    echo "Detected architecture: $ARCH"
    exit 1
fi

case "$ID" in
    ubuntu)
        DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
        ;;
    debian|raspbian)
        DOCKER_REPO_URL="https://download.docker.com/linux/debian"
        ;;
    *)
        echo "Unsupported OS: $ID"
        echo "Supported: Ubuntu, Debian, Raspberry Pi OS"
        exit 1
        ;;
esac

echo "OS: $PRETTY_NAME"
echo "Codename: $CODENAME"
echo "Architecture: $ARCH"
echo "Docker repo: $DOCKER_REPO_URL"

echo "[2] Remove old Docker repo files..."
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/sources.list.d/docker.*

echo "[3] Install prerequisites..."
sudo apt update
sudo apt install -y ca-certificates curl gnupg

echo "[4] Add Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL "$DOCKER_REPO_URL/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "[5] Add Docker repository..."
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] $DOCKER_REPO_URL $CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[6] Install Docker..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[7] Enable and start Docker..."
sudo systemctl enable docker
sudo systemctl start docker

echo "[8] Add current user to docker group..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker "$USER_NAME"

echo "[9] Fix Docker socket permission..."
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

echo
echo "=== Test with sudo ==="
sudo docker run hello-world || true

echo
echo "=== Test without sudo ==="
newgrp docker <<EONG
docker run hello-world || echo "Logout/login may be required."
EONG

echo
echo "Docker installation completed."
echo "If permission is denied, logout and login again."