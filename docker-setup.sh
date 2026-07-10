#!/usr/bin/env bash

set -e

APP_NAME="Docker Raspberry Pi Manager"
USER_NAME="$(whoami)"

detect_raspberry_pi() {
    if ! grep -qi "raspberry pi" /proc/device-tree/model 2>/dev/null; then
        echo "This installer is only for Raspberry Pi."
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
    else
        echo "Cannot detect OS."
        exit 1
    fi

    ARCH="$(dpkg --print-architecture)"
    CODENAME="${VERSION_CODENAME}"

    case "$ARCH" in
        arm64|armhf)
            ;;
        *)
            echo "Unsupported architecture: $ARCH"
            echo "Supported Raspberry Pi architectures: arm64, armhf"
            exit 1
            ;;
    esac

    case "$ID" in
        ubuntu)
            DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
            ;;
        debian|raspbian)
            DOCKER_REPO_URL="https://download.docker.com/linux/debian"
            ;;
        *)
            echo "Unsupported OS: $ID"
            echo "Supported: Raspberry Pi OS, Debian, Ubuntu"
            exit 1
            ;;
    esac
}

install_docker() {
    detect_raspberry_pi
    detect_os

    echo "Installing Docker on Raspberry Pi..."
    echo "OS: $PRETTY_NAME"
    echo "Codename: $CODENAME"
    echo "Architecture: $ARCH"

    sudo rm -f /etc/apt/sources.list.d/docker.list
    sudo rm -f /etc/apt/sources.list.d/docker.*

    sudo apt update
    sudo apt install -y ca-certificates curl gnupg

    sudo install -m 0755 -d /etc/apt/keyrings

    curl -fsSL "$DOCKER_REPO_URL/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] $DOCKER_REPO_URL $CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable docker
    sudo systemctl start docker

    sudo groupadd docker 2>/dev/null || true
    sudo usermod -aG docker "$USER_NAME"

    sudo chown root:docker /var/run/docker.sock
    sudo chmod 660 /var/run/docker.sock

    echo
    echo "Docker installed successfully."
    echo "Run this command if Docker needs permission refresh:"
    echo "newgrp docker"
}

status_docker() {
    echo "Docker service status:"
    sudo systemctl status docker --no-pager || true

    echo
    echo "Docker version:"
    docker version || true

    echo
    echo "Docker Compose version:"
    docker compose version || true

    echo
    echo "Docker containers:"
    docker ps -a || true
}

uninstall_docker() {
    echo "Stopping Docker..."
    sudo systemctl stop docker 2>/dev/null || true
    sudo systemctl disable docker 2>/dev/null || true

    echo "Removing Docker packages..."
    sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true

    echo "Removing Docker repository..."
    sudo rm -f /etc/apt/sources.list.d/docker.list
    sudo rm -f /etc/apt/sources.list.d/docker.*
    sudo rm -f /etc/apt/keyrings/docker.gpg

    echo "Removing Docker data..."
    read -r -p "Remove all Docker images, containers and volumes? [y/N]: " CONFIRM

    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        echo "Docker data removed."
    else
        echo "Docker data kept."
    fi

    sudo apt update

    echo
    echo "Docker uninstalled."
}

show_menu() {
    echo "=============================="
    echo "$APP_NAME"
    echo "=============================="
    echo "1) Install Docker"
    echo "2) Docker Status"
    echo "3) Uninstall Docker"
    echo "4) Exit"
    echo "=============================="
}

while true; do
    show_menu
    read -r -p "Choose an option: " CHOICE

    case "$CHOICE" in
        1)
            install_docker
            ;;
        2)
            status_docker
            ;;
        3)
            uninstall_docker
            ;;
        4)
            echo "Exit."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac

    echo
done