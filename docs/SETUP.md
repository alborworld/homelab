# Homelab Setup Guide

## Prerequisites

- Git
- Docker and Docker Compose
- SOPS (Secrets OPerationS) for secret management
- SSH access to all nodes

## Initial Setup

1. **Clone the repository**:
   ```bash
   git clone git@github.com:alborworld/homelab.git
   cd homelab
   ```

2. **Set up SOPS** (if not already configured):
   - Install SOPS: `brew install sops`
   - Set up your encryption key (see SECURITY.md for details)

3. **Environment Configuration**:
   - Copy and customize the example environment files:
     ```bash
     cp .env.example .env
     cp docker/.env.example docker/.env
     ```
   - Edit the `.env` files with your specific configuration

## Host-Specific Setup

### Raspberry Pi 5
```bash
# On your local machine
make setup-raspberrypi
```

### Docker Host (Proxmox VM)
```bash
# On the Docker host
make setup-dockerhost
```

### Synology DiskStations

- **DS218+ (Primary NAS)**: Main storage and services
- **DS214 (Backup NAS)**: Offsite backup target for DS218+ data

Refer to the [Synology Backup NAS Setup Guide](README_Synology_DS214.md) for detailed configuration instructions on setting up the backup target.

## Verifying the Setup

1. Check all services are running:
   ```bash
   make status
   ```

2. Access the monitoring dashboard at `https://monitor.yourdomain.com`

## Troubleshooting

- **Docker issues**: Run `docker-compose logs [service]` to check logs
- **Network issues**: Verify ports are open and services are reachable
- **SOPS errors**: Ensure your GPG key is imported and accessible

For additional help, check the [Troubleshooting Guide](TROUBLESHOOTING.md).
