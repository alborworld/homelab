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

2. **Set up environment and symlinks** (run the appropriate section for your host):

   **Raspberry Pi 5**:
   ```bash
   # Add to ~/.zprofile_local or your shell's login profile
   echo 'export COMPOSEDIR=~/docker/compose' >> ~/.zprofile_local
   
   # Create symlink
   ln -s ~/homelab/docker/raspberrypi5 $COMPOSEDIR
   ```

   **Dockerhost (Proxmox VM)**:
   ```bash
   # Add to ~/.zprofile_local or your shell's login profile
   echo 'export COMPOSEDIR=~/docker/compose' >> ~/.zprofile_local
   
   # Create symlink
   ln -s ~/homelab/docker/dockerhost $COMPOSEDIR
   ```

   **Diskstation (DS218+)**:
   ```bash
   # Add to ~/.profile or your shell's login profile
   echo 'export COMPOSEDIR=/volume1/docker/compose' >> ~/.profile
   
   # Create symlink
   ln -s ~/homelab/docker/diskstation $COMPOSEDIR
   ```

   After adding the export, either log out and back in or run `source ~/.zprofile_local` (or the appropriate profile file) to apply the changes.

3. **Deploy services**:
   ```bash
   cd $COMPOSEDIR
   make decrypt  # Decrypt environment variables
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
