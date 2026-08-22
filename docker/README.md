# Docker Configuration

This directory contains the Docker configuration for all nodes in the homelab. Each node is a separate Docker host with its own services and configuration.

## 📁 Subdirectory Structure

```
docker/
├── diskstation/      # Synology DS218+ services
├── dockerhost/       # Proxmox VM (main Docker host)
└── raspberrypi5/     # Edge node services
```

### Node Roles

1. **raspberrypi5** (Edge Node)
   - Always-on, low-power node
   - Critical infrastructure services
   - Main DNS server (AdGuard Home)
   - [Details](raspberrypi5/README.md)

2. **diskstation** (Synology DS218+)
   - Secondary infrastructure services
   - S3-compatible storage
   - File synchronization
   - [Details](diskstation/README.md)

3. **dockerhost** (Proxmox VM)
   - Resource-intensive applications
   - Media services stack
   - [Details](dockerhost/README.md)

## 🔧 Getting Started

### Prerequisites
- Docker Engine and Docker Compose installed on each host
- SOPS with age encryption configured
- Access to the homelab network

### Quick Start

1. **Clone the repository** on each host:
   ```bash
   git clone git@github.com:alborworld/homelab.git ~/homelab
   ```

2. **Create the compose symlink** (run the line for your host):

   ```bash
   # raspberrypi5 / dockerhost — create the PARENT dir, not the link itself
   mkdir -p ~/docker
   ln -s ~/homelab/docker/raspberrypi5 ~/docker/compose   # or .../dockerhost

   # diskstation
   ln -s ~/homelab/docker/diskstation /volume1/docker/compose
   ```

   No shell variables need exporting. The paths the compose files actually use
   (`VOLUMEDIR`, `LOCAL_DOMAIN`, `UID`/`GID`, and `MEDIADIR` on dockerhost) come from the
   host's `.env`, not from your login profile.

3. **Ship the secrets**, from the repo root on your workstation:

   ```bash
   make deploy-raspberrypi5    # decrypt .env.sops.enc and pipe it to the host over ssh
   ```

   See [SETUP.md](../docs/SETUP.md#2-ship-the-secrets) for the other Makefile targets and
   the diskstation caveat.

4. **Start the services**, on the host:

   ```bash
   cd ~/docker/compose         # /volume1/docker/compose on diskstation
   docker compose up -d
   ```

## 🔒 Security

- All secrets are encrypted using SOPS with age
- Never commit unencrypted `.env` files
- Use the provided [Makefile](../Makefile) targets for encryption/decryption

### Managing Secrets

For detailed information on secrets management using SOPS, including encryption/decryption procedures and best practices, please refer to the [Secrets Management with SOPS](../docs/SECURITY.md#secrets-management-with-sops) section in the security documentation.

## 🛠️ Maintenance

### Updating Services
```bash
cd $COMPOSEDIR
# Pull latest images and recreate containers
docker compose pull
docker compose up -d --force-recreate

# Remove unused images
docker image prune -f
```

## 📚 Documentation

- [Architecture](../docs/ARCHITECTURE.md)
- [Setup Guide](../docs/SETUP.md)
- [Security Practices](../docs/SECURITY.md)
