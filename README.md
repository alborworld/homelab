# AlborWorld's Homelab

A modular, GitOps-driven homelab infrastructure spanning multiple devices, designed for automation and maintainability.

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
- **Compute Node**: Intel NUC 13 (64 GB RAM, 2 TB SSD) running Proxmox
- **Edge Node**: Raspberry Pi 5 (4 GB RAM, 64 GB SSD)

## 🧩 Architecture

### Docker Hosts
- **raspberrypi5**: Always-on edge node
  - Critical services (AdGuard Home)
  - High-availability DNS
- **diskstation**: Synology Docker host
  - Managed via Synology's Docker package
- **dockerhost**: Ubuntu VM on Proxmox
  - Main container orchestration
  - Secondary DNS server

### Infrastructure Features
- **DNS**: High-availability setup using AdGuard Home
- **Power Management**: Automated shutdown schedule (midnight to 6 AM) for diskstation and dockerhost
- **Security**: Secrets management using SOPS encryption

## 📁 Repository Structure

```
homelab/
├── diskstation/          # Synology NAS configurations
│   ├── docker-compose.yaml
│   └── .env.sops.yaml    # Encrypted environment variables
├── dockerhost/          # Proxmox VM configurations
│   ├── docker-compose.yaml
│   └── .env.sops.yaml
└── raspberrypi5/        # Raspberry Pi configurations
    ├── docker-compose.yaml
    └── .env.sops.yaml
```

Each host directory contains:
- `docker-compose.yaml`: Service definitions
- `.env.sops.yaml`: Encrypted environment variables
- `volumes/`: Persistent data (git-ignored)

## 🔐 Security

- Environment variables and secrets are encrypted using [SOPS](https://github.com/mozilla/sops)
- Encrypted `.env.sops.yaml` files are version controlled
- Plaintext secrets are never committed to the repository

## 🚧 Roadmap

- [ ] Implement Ansible playbooks for automated provisioning
- [ ] Deploy Prometheus and Grafana for infrastructure monitoring
- [ ] Set up CI/CD pipelines for automated deployments
- [ ] Set up K3s cluster on Proxmox
- [ ] Set up GitOps with ArgoCD
- [ ] Document comprehensive backup and recovery procedures
- [ ] Implement automated testing for infrastructure changes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.