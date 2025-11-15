# Gemini Code Assistant Context

This document provides context for the Gemini Code Assistant to understand the homelab infrastructure project.

## Directory Overview

This repository contains the configuration and orchestration files for a personal homelab environment. The infrastructure is designed to be modular, maintainable, reproducible, and driven by GitOps principles for automated deployments. The primary technologies used are Docker, Docker Compose, and SOPS for secrets management. The project is structured to manage services across multiple Docker hosts: a Raspberry Pi 5, a Synology DiskStation, and a Proxmox VM.

## Key Files

*   `README.md`: The main entry point for understanding the project, including an overview of the architecture, hardware, and technology stack.
*   `docs/ARCHITECTURE.md`: Provides a detailed overview of the homelab's architecture, including hardware topology, network layout, service orchestration, and storage/backup strategies.
*   `docs/SETUP.md`: Contains step-by-step instructions for setting up the homelab environment, including prerequisites and host-specific setup instructions.
*   `docs/SECURITY.md`: Describes the security practices, with a focus on secrets management using SOPS with age encryption. It includes commands for encrypting and decrypting sensitive environment variables.
*   `docs/DEPLOYMENT.md`: Outlines the procedures for deploying and updating services, including development, staging, and production deployment workflows, as well as rollback procedures.
*   `docker/README.md`: Explains the structure of the Docker configurations, with separate directories for each Docker host (Raspberry Pi, DiskStation, and Dockerhost).
*   `Makefile`: Provides convenient make targets for encrypting, decrypting, and managing SOPS-encrypted `.env` files for each of the Docker hosts.

## Usage

The contents of this directory are used to manage a personal homelab. The general workflow is:

1.  **Configuration:** Modify the Docker Compose files and environment variables for the desired services.
2.  **Secrets Management:** Use `sops` and the provided `Makefile` to encrypt sensitive information in `.env` files.
3.  **Deployment:** Use `git` to version control the configuration and `docker-compose` to deploy the services on the respective hosts.

## Commit & Pull Request Guidelines
When committing:
- Check the changes by doing a git diff.
- Use single-line commit messages with conventional commits format and gitmoji. Avoid Codex attributions.
- Match the current log style: `<emoji> <type>(scope): summary` such as `🐛 fix(runners): add startup delay`.
- Keep commits narrow (docs, secrets, infra separated) and include any generated files (diagrams, screenshots) in the same change.
- The single line is mandatory, except for breaking changes - which will have a second comment line.
- PRs need a short summary, links to issues or project cards, and a checklist of the commands above that were executed, plus pasted `tofu plan`/`docker compose config` diffs when relevant.

The repository is structured to support a GitOps workflow, where changes pushed to the Git repository trigger automated deployments to the homelab infrastructure.
