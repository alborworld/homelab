# 🧪 Dockerhost (Proxmox VM) — HomeLab Docker Stack

This folder contains the Docker Compose configuration and related files for services running on the Dockerhost Proxmox VM in the [alborworld/homelab](https://github.com/alborworld/homelab) setup.

> For common setup instructions, SOPS usage, and general information, please refer to the [main README](../../README.md). For a detailed architecture overview, see [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md).

## 📦 Services

The services are defined by the `docker-compose.yaml` file in each relative subfolder.

## 📂 Local Folder Structure

```bash
~/docker/
├── compose/           # ← This repo's docker/ content is symlinked here
│   ├── docker-compose.yaml
│   ├── .env.sops.enc
│   └── ...
└── volumes/           # ← Local persistent data (NOT versioned)
~/homelab/             # ← Cloned repo
```

## 📋 Host-Specific Notes

- Main container orchestration
- Secondary DNS server
- Scheduled downtime: midnight to 6 AM
- Located at `~/docker/compose` when symlinked

## 🚀 Quick Start

1. Clone and symlink:
   ```bash
   git clone git@github.com:alborworld/homelab.git ~/homelab
   ln -s ~/homelab/docker/dockerhost ~/docker/compose
   ```

2. Deploy:
   ```bash
   make decrypt-dockerhost
   cd ~/docker/compose
   docker compose up -d
   ```
