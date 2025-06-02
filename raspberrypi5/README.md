# 🧪 Raspberry Pi 5 — HomeLab Docker Stack

This folder contains the Docker Compose configuration and related files for services running on the Raspberry Pi 5 in the [alborworld/homelab](https://github.com/alborworld/homelab) setup.

> For common setup instructions, SOPS usage, and general information, please refer to the [main README](../README.md).

## 📦 Services

The services are defined by the `docker-compose.yaml` file in each relative subfolder.

## 📂 Local Folder Structure

```bash
~/docker/
├── compose/           # ← This repo's content is symlinked here
│   ├── docker-compose.yaml
│   ├── .env.sops.enc
│   └── ...
└── volumes/           # ← Local persistent data (NOT versioned)
~/homelab/            # ← Cloned repo
```

## 📋 Host-Specific Notes

- Always-on edge node (24/7)
- Critical services (AdGuard Home)
- High-availability DNS
- Located at `~/docker/compose` when symlinked

## 🚀 Quick Start

1. Clone and symlink:
   ```bash
   git clone git@github.com:alborworld/homelab.git ~/homelab
   ln -s ~/homelab/raspberrypi5 ~/docker/compose
   ```

2. Deploy:
   ```bash
   cd ~/docker/compose
   sops --input-type dotenv --output-type dotenv --decrypt .env.sops.enc > .env
   docker compose up -d
   ```
