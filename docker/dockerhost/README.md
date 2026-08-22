# 🐳 Docker Host (Proxmox VM)

> **Note**: For general setup, security practices, and deployment instructions, please refer to the [main documentation](../../docs/).

## 📦 Services

This directory contains the Docker Compose configuration for services running on the Docker host Proxmox VM.

## 📂 Directory Structure

```
dockerhost/
├── docker-compose.yaml    # Main Compose file
├── .env.sops.enc         # Encrypted environment variables
├── config/               # Service configurations
└── scripts/              # Helper scripts
```

## 🏷️ Host-Specific Configuration

- **Role**: Main container orchestration host
- **Location**: `~/docker/compose` (symlinked)
- **Availability**: 24/7 (except maintenance windows)
- **Scheduled Maintenance**: Midnight to 6 AM daily

## 🚀 Quick Start

1. **Clone the repository**:
   ```bash
   git clone git@github.com:alborworld/homelab.git ~/homelab
   ```

2. **Set up the directory structure**:
   ```bash
   mkdir -p ~/docker
   ln -s ~/homelab/docker/dockerhost ~/docker/compose
   ```
   Create the parent directory only — `mkdir -p ~/docker/compose` would make the symlink
   land *inside* it instead of creating it.

3. **Decrypt secrets**:
   ```bash
   cd ~/homelab
   make decrypt-dockerhost
   ```

4. **Start services**:
   ```bash
   cd ~/docker/compose
   docker compose up -d
   ```

## 🔧 Maintenance

- **Logs**: `docker compose logs -f`
- **Updates**: `docker compose pull && docker compose up -d`
- **Backups**: Managed by Proxmox Backup Server

## 🔗 Related Documentation

- [Deployment Guide](../../docs/DEPLOYMENT.md)
- [Security Practices](../../docs/SECURITY.md)
- [Setup Guide](../../docs/SETUP.md)
