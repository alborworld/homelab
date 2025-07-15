# 🏗️ Homelab Architecture

## Overview

This document provides a detailed overview of the architecture for AlborWorld's Homelab, including hardware, network topology, service orchestration, and security practices.

## Hardware Topology

- **Router:** Synology RT2600ac
- **Compute Node:** Intel NUC 13 running Proxmox VE (VM host)
- **Edge Node:** Raspberry Pi 5 (always-on, critical services)
- **NAS:** Synology DiskStation DS218+ (primary) and DS214 (backup)

## Network Layout

- All nodes are connected via a secure, VLAN-segmented home network.
- The router provides DHCP, firewall, and VPN gateway services.
- The NAS and compute nodes are on a protected LAN; the Raspberry Pi is on a separate VLAN for edge services.

## Service Orchestration

- **Docker Compose** is used for container orchestration on all nodes.
- **Proxmox VE** manages VMs, including the main Dockerhost.
- **Traefik** acts as a reverse proxy, providing SSL termination and service discovery across hosts.
- **AdGuard Home** provides high-availability DNS, running on both the Raspberry Pi and DiskStation (DS218+) - using [AdGuard Home Sync]](https://github.com/bakito/adguardhome-sync).
- **Watchtower** automates container updates.
- **SOPS** is used for secrets management, with all sensitive environment variables encrypted and version-controlled.

## Storage & Backups

- The DS218+ serves as the main NAS for media and data storage.
- The DS214 is dedicated to backups and is located in a separate physical location for additional redundancy.
- Persistent data for containers is stored in host-specific `volumes/` directories, which are excluded from version control.
- **Backups follow the 3-2-1 approach:**
  - **Proxmox Backup Server** backs up all VMs to the DS218+ NAS, ensuring virtual machine data is protected and efficiently stored through deduplication.
  - For the Raspberry Pi 5, `raspiBackup` is used to create regular full-image backups of the 64 GB SD card, providing comprehensive recovery options.
  - **HyperBackup** is used to back up the DS218+ NAS to a 5 TB USB drive, providing an additional local copy.
  - **HyperBackup** also backs up the DS214 NAS, which is kept offsite, ensuring geographic redundancy and protection against local disasters.
- _All of these backups are performed daily to ensure up-to-date recovery points._

## Security Practices

- All secrets and environment variables are encrypted with SOPS.
- Access to the homelab is restricted via VPN and firewall rules.
- Automated updates and monitoring are in place to ensure system health and minimize vulnerabilities.
- **Single Sign-On (SSO):** PocketID is used to provide secure SSO (via OIDC and passkey) for several services, including Portainer, Proxmox VE, Proxmox Backup Server, Synology Diskstation, Home Assistant, Beszel, and others.

## Automation & CI/CD

- Infrastructure as Code: All configuration is managed via Git.
- CI/CD pipelines (via GitLab Runner) are used for testing and deploying configuration changes.
- Ansible and Terraform/OpenTofu are planned for further automation of VM provisioning and configuration.

## Roadmap

For the latest roadmap and planned features, see the [GitHub Projects board](https://github.com/users/alborworld/projects/3/views/4).

---

*For more details on each host and service, refer to the respective README files in each directory.*
