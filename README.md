# AlborWorld's Homelab

A modular, GitOps-driven homelab infrastructure designed to provide security, privacy, and data ownership while automating and maintaining services across multiple devices.

> ⚠️ **Work in Progress**: This repository is under active development. Expect changes and improvements over time.

## 🏠 Overview

This repository contains the configuration and orchestration files for a personal homelab environment. The infrastructure is designed to be:
- Modular and maintainable
- Reproducible across different environments
- GitOps-driven for automated deployments
- Energy-efficient with scheduled power management

## 📊 Dashboard

![Homelab Dashboard](docs/images/dashboard.png)

*Overview of running services and applications across the homelab infrastructure*

## 🖥️ Hardware Infrastructure

### Core Components
- **Router**: Synology RT2600ac
- **NAS**: Synology DiskStation DS218+ (10 GB RAM, 2 x 5 TB HD)
- **Compute Node**: Intel NUC 13 (64 GB RAM, 2 TB SSD) running Proxmox VE
- **Edge Node**: Raspberry Pi 5 (4 GB RAM, 64 GB SSD)

## 🧩 Architecture

### Docker Hosts
- **raspberrypi5**: Always-on edge node
  - Critical services (AdGuard Home)
  - High-availability DNS
- **diskstation**: Synology Docker host
  - Managed via Synology's Docker package
- **dockerhost**: Ubuntu VM on Proxmox VE
  - Main container orchestration
  - Secondary DNS server

### Infrastructure Features
- **DNS**: High-availability setup using AdGuard Home
- **Power Management**: Automated shutdown schedule (midnight to 6 AM) for diskstation and dockerhost
- **Security**: Secrets management using SOPS encryption

## 🛠️ Technology Stack

### Core Technologies
- **Containerization**: Docker & Docker Compose v2.21.0+
- **Secrets Management**: Mozilla SOPS for encrypted .env files
- **Reverse Proxy**: Traefik v3.4 with automatic SSL
- **DNS**: AdGuard Home with high-availability setup
- **VPN**: WireGuard via Gluetun container
- **Monitoring**: 
  - Uptime Kuma for service monitoring
  - Speedtest Tracker for network performance
  - UpSnap for device power management

### Media Stack
- **Media Management**: 
  - Plex for media streaming
  - Sonarr, Radarr, Readarr for media automation
  - Prowlarr for indexer management
  - NZBGet & qBittorrent for downloads
  - Tautulli for Plex analytics
  - Tdarr for media transcoding

### Productivity
- **File Sharing**: Nextcloud with OnlyOffice integration
- **Document Management**: OnlyOffice Document Server
- **Version Control**: GitLab Runner for CI/CD

### Infrastructure
- **Container Management**: Portainer Agent
- **Service Discovery**: Traefik Kop for multi-host setup
- **Automation**: Watchtower for container updates
- **Monitoring**: Beszel Agent for disk monitoring

## 📁 Repository Structure

```
homelab/
├── diskstation/          # Synology NAS configurations
│   ├── docker-compose.yaml
│   └── .env.sops.enc     # Encrypted environment variables
├── dockerhost/          # Proxmox VM configurations
│   ├── docker-compose.yaml
│   └── .env.sops.enc
└── raspberrypi5/        # Raspberry Pi configurations
    ├── docker-compose.yaml
    └── .env.sops.enc
```

Each host directory contains:
- `docker-compose.yaml`: Service definitions
- `.env.sops.enc`: Encrypted environment variables
- `volumes/`: Persistent data (git-ignored)

## 🔐 Security

- Environment variables and secrets are encrypted using [SOPS](https://github.com/mozilla/sops)
- Encrypted `.env.sops.enc` files are version controlled
- Plaintext secrets are never committed to the repository

### SOPS Usage

#### Encryption
To encrypt an existing `.env` file:
```bash
sops --encrypt .env > .env.sops.enc
```

#### Decryption
After cloning, decrypt with:
```bash
sops --input-type dotenv --output-type dotenv --decrypt .env.sops.enc > .env
```

> **Note**: When decrypting with SOPS, specifying `--input-type dotenv --output-type dotenv` ensures that the file is correctly interpreted and formatted as a dotenv file, preserving its structure and avoiding misinterpretation or formatting issues.

## 🚀 Common Usage

### Clone and Setup
1. Clone the repository:
   ```bash
   git clone git@github.com:alborworld/homelab.git ~/homelab
   ```

2. For each host, create a symlink to the appropriate directory:
   ```bash
   # For Raspberry Pi
   ln -s ~/homelab/raspberrypi5 ~/docker/compose
   
   # For Dockerhost
   ln -s ~/homelab/dockerhost ~/docker/compose
   
   # For Diskstation
   ln -s ~/homelab/diskstation /volume1/docker/compose
   ```

### Deployment
For each host, deploy using:
```bash
cd ~/docker/compose  # or /volume1/docker/compose for Diskstation
sops --input-type dotenv --output-type dotenv --decrypt .env.sops.enc > .env
docker compose up -d
```

## 🚧 Roadmap

- [x] Set up private HTTPS Access (with Traefik, CloudFlare)
- [x] Set up Authorization with PocketID
- [ ] Set up K3s cluster on pve
- [ ] Use Terraform/OpenTofu to provision VMs in Proxmox and deploy Cloudflare distributions
- [ ] Use Ansible playbooks for automated setup and orchestration of VMs, Diskstation, and Raspberry Pi
- [ ] Deploy Prometheus and Grafana for infrastructure monitoring
- [ ] Set up CI/CD pipelines for automated deployments
- [ ] Set up GitOps with ArgoCD
- [ ] Set up Unbound for recursive DNS
- [ ] Document comprehensive backup and recovery procedures
- [ ] Implement automated testing for infrastructure changes

... and much more.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.