# AlborWorld's Homelab

A modular, GitOps-driven homelab infrastructure designed to provide security, privacy, and data ownership while automating and maintaining services across multiple devices.

> 🧪 Continuously evolving platform used to evaluate infrastructure technologies and operational practices.

## 📚 Documentation

- [**Architecture**](docs/ARCHITECTURE.md) - Detailed overview of the homelab's architecture
- [**Setup Guide**](docs/SETUP.md) - Step-by-step instructions for setting up the homelab
- [**Security Practices**](docs/SECURITY.md) - Security guidelines and secrets management
- [**Deployment Guide**](docs/DEPLOYMENT.md) - Procedures for deploying and updating services

## 🏠 Overview

This repository contains the configuration and orchestration files for a personal homelab environment. The infrastructure is designed to be:
- 🔄 **Modular and maintainable**
- 🔄 **Reproducible** across different environments
- 🔄 **GitOps-driven** for automated deployments
- 🔄 **Energy-efficient** with scheduled power management

### 📊 Dashboard

![Homelab Dashboard](docs/images/dashboard.png)

## 🖥️ Hardware Infrastructure

### Core Components
- **Router**: Synology RT2600ac
- **NAS**: Synology DiskStation DS218+ (10 GB RAM, 2 x 5 TB HD)
- **Backup NAS**: Synology DiskStation DS214 (512 MB RAM, 2 x 1.8 TB HD) - Offsite backup
- **Compute Node**: Intel NUC 13 (64 GB RAM, 2 TB SSD) running Proxmox VE
- **Edge Node**: Raspberry Pi 5 (4 GB RAM, 64 GB SSD)

## 🧩 Architecture

### Docker Hosts
- **raspberrypi5**: Always-on edge node
  - Main DNS server
  - Critical services
- **diskstation**: Synology Docker host
  - Secondary DNS server
  - S3-compatible object storage
  - File synchronization
- **dockerhost**: Ubuntu VM on Proxmox VE
  - Media services stack
  - Resource-intensive applications

For detailed architecture and service information, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## 🛠️ Technology Stack

### Core Infrastructure
- **Containerization**: Docker & Docker Compose v2.21.0+ — selected over Kubernetes because the fleet is a handful of heterogeneous, mostly single-node hosts (a Synology NAS, a Raspberry Pi, one VM) where Kubernetes adds operational overhead without delivering its scheduling and self-healing benefits. Compose `include` files per service keep the setup declarative and Git-driven; a K3s migration is on the roadmap for when the service count justifies it.
- **Infrastructure as Code**: OpenTofu (Proxmox, Cloudflare, Garage) and Ansible — OpenTofu owns *what exists* (VMs, LXC containers, DNS records), Ansible owns *how it's configured* (software, Tailscale enrollment, firewall rules). Keeping the two concerns separate makes either side reproducible on its own.
- **Secrets Management**: SOPS with age encryption — chosen because encrypted secrets can live in the repo itself, so the entire configuration stays version-controlled without depending on an always-on secrets server.
- **Reverse Proxy**: Traefik v3.4 with automatic SSL — chosen because it discovers services from Docker labels, so routing config lives next to each service's compose file instead of in a central config, and certificates renew automatically via DNS-01. `traefik-kop` extends the same single entry point to the satellite Docker hosts.
- **DNS**: AdGuard Home / Unbound (HA setup) — primary on the always-on Pi with a synced replica on the NAS, because DNS is the one service whose failure takes the whole household offline.
- **VPN Mesh**: Tailscale (with NordVPN exit node) — chosen because it provides encrypted host-to-host connectivity and remote access with zero port forwarding, so nothing needs to be exposed to the public internet.
- **Identity/SSO**: Pocket ID
- **Object Storage**: Garage (S3-compatible) — chosen because it runs comfortably on modest NAS hardware and doubles as the S3 state backend for OpenTofu.
- **Monitoring**: Beszel, Uptime Kuma, Dozzle, Speedtest Tracker, UpSnap
- **Image Updates**: WUD (What's Up Docker) — chosen over auto-updaters like Watchtower because it notifies about new images rather than blindly replacing running containers, keeping updates deliberate.

### Media Stack
- **Media**: Plex, Sonarr, Radarr, Readarr, Prowlarr, Seerr
- **Download Clients**: NZBGet, qBittorrent (via gluetun VPN)
- **Media Processing**: Unmanic, Tautulli

### Documents & Knowledge
- **Documents**: Paperless-ngx, Stirling-PDF
- **Reading**: Booklore, Audiobookshelf

### Home & Files
- **Home Automation**: Home Assistant
- **File Sync**: Syncthing

## 🤖 AI Platform

The homelab doubles as a self-hosted AI platform — a place to run assistants and experiment with LLM tooling on infrastructure I control:

- **Local AI gateway — OpenClaw**: an AI assistant gateway running in a dedicated LXC container on Proxmox, reachable via a Telegram bot. Voice notes are transcribed locally with Whisper (faster-whisper on CPU) and responses can be spoken back via Edge TTS, while model inference goes out over HTTPS to external APIs. The container's full lifecycle is managed as code: OpenTofu provisions it, Ansible configures it.
- **LLM experimentation — Open WebUI**: a chat interface for trying out models, prompts, and tools without committing to any single vendor's UI.
- **Automation — n8n**: workflow engine that wires services together and provides the glue for AI-triggered automations.
- **AI-assisted workflows**: the combination of the gateway, n8n, and the rest of the stack turns everyday operations (notifications, document handling with Paperless-ngx, media requests) into workflows an assistant can participate in.

AI dashboards are reachable only over the Tailscale mesh — nothing is exposed to the public internet.

## 📁 Repository Structure

```
homelab/
├── ansible/          # Ansible playbooks (VMs, LXC, Tailscale)
├── tofu/             # OpenTofu stacks (Proxmox, Cloudflare, Garage)
├── docker/           # Docker configurations (see docker/README.md)
├── k8s/              # Kubernetes configurations (future)
├── docs/             # Documentation
└── Makefile          # Common tasks
```

## 🔐 Security

- All secrets are encrypted using [SOPS](https://github.com/mozilla/sops) with age
- Encrypted `.env.sops.enc` files are version controlled
- Plaintext secrets are never committed to the repository
- See [Security Practices](docs/SECURITY.md) for details on secrets management

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone git@github.com:alborworld/homelab.git ~/homelab
   ```

2. Follow the [Setup Guide](docs/SETUP.md) for host-specific instructions

3. For Docker deployments, see [docker/README.md](docker/README.md)

## 🚧 Roadmap

With the number of services now approaching 50, it's time to upgrade the homelab's orchestration to Kubernetes for improved scalability, reliability, and management.

Here are some of the planned improvements and features for the homelab:

- [x] Use Terraform/OpenTofu to provision VMs in Proxmox and deploy Cloudflare distributions
- [x] Use Ansible playbooks for automated setup and orchestration of VMs, Diskstation, and Raspberry Pi
- [ ] Set up K3s cluster on pve
- [ ] Set up GitOps with ArgoCD
- [ ] Deploy HashiCorp Vault / OpenBao for centralized and seamless secrets management
- [ ] Deploy Prometheus and Grafana for infrastructure monitoring
- [ ] Set up CI/CD pipelines for automated deployments

For the latest roadmap and planned features, see the [GitHub Projects board](https://github.com/users/alborworld/projects/3/views/4).

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.