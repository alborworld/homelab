# 🧪 Synology Diskstation — HomeLab Docker Stack

This folder contains the Docker Compose configuration and related files for services running on the Synology Diskstation in the [alborworld/homelab](https://github.com/alborworld/homelab) setup.

> For common setup instructions, SOPS usage, and general information, please refer to the [main README](../README.md).

## 📦 Services

The services are defined by the `docker-compose.yaml` file in each relative subfolder.

## 📂 Local Folder Structure

```bash
/volume1/docker/
├── compose/           # ← This repo's content is symlinked here
│   ├── docker-compose.yaml
│   ├── .env.sops.enc
│   └── ...
└── volumes/           # ← Local persistent data (NOT versioned)
~/homelab/            # ← Cloned repo
```

## 📋 Host-Specific Notes

- Managed via Synology's Docker package
- Scheduled downtime: midnight to 6 AM
- Requires Docker Compose v2.21.0 or later
- Located at `/volume1/docker/compose` when symlinked

## 🚀 Quick Start

1. Clone and symlink:
   ```bash
   git clone git@github.com:alborworld/homelab.git ~/homelab
   ln -s ~/homelab/diskstation/docker /volume1/docker/compose
   ```

2. Deploy:
   ```bash
   make decrypt-diskstation
   cd /volume1/docker/compose
   docker compose up -d
   ```
