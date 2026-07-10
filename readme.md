# Raspberry Pi Installation Guide

## Supported Systems

- Raspberry Pi 4
- Raspberry Pi 5

### Supported Operating Systems

- Ubuntu 22.04
- Ubuntu 24.04
- Raspberry Pi OS Bookworm (64-bit)
- Debian 12 Bookworm

---

## Clone Repository

```bash
git clone https://github.com/6a6ak/UTU_Docker_Manager.git
cd UTU_Docker_Manager
```

---

## Make Script Executable

```bash
chmod +x docker_manager.sh
```

---

## Run Installer

Run as your normal user.

Do NOT use sudo.

```bash
bash docker_manager.sh
```

The script automatically:

- Detects Ubuntu or Debian
- Adds the official Docker repository
- Installs Docker Engine
- Installs Docker Compose Plugin
- Installs Buildx
- Enables Docker service
- Adds your user to the docker group
- Tests the installation

---

## Verify Installation

```bash
docker version
docker compose version
docker run hello-world
```

---

## If Permission Denied

```bash
newgrp docker
```

or simply logout and login again.

---

## Supported Architectures

```text
arm64
amd64
```

---

## Raspberry Pi Notes

A 64-bit operating system is strongly recommended.

Docker performs significantly better on Raspberry Pi 5 with SSD/NVMe storage than with SD cards.

The installer automatically detects:

- Ubuntu
- Debian
- Raspberry Pi OS

and configures the appropriate Docker repository.
