# Homelab Repository Guidelines

## Committing

- Check changes with `git diff` before committing
- Use single-line commit messages with conventional commits format and gitmoji
- Avoid Claude attributions
- Single line mandatory, except for breaking changes (add second line)

## Repository Structure

```
homelab/
├── docker/                    # Docker Compose stacks per host
│   ├── diskstation/          # Synology DS218+ services
│   ├── dockerhost/           # Proxmox VM (main Docker host)
│   └── raspberrypi5/         # Edge node (always-on, low-power)
├── tofu/                      # OpenTofu infrastructure
│   ├── cloudflare/           # DNS and security rules
│   ├── garage/               # S3 storage cluster
│   └── proxmox/              # LXC containers and VMs
├── ansible/                   # Configuration management
├── docs/                      # Documentation
└── Makefile                   # SOPS encryption helpers
```

## SSH Host Access

All hosts are configured in `~/.ssh/config`:

| Host | User | Description |
|------|------|-------------|
| `raspberrypi5` | pi | Edge node - Homepage, AdGuard, Traefik, Home Assistant |
| `dockerhost` | albor | Proxmox VM - Media stack (Plex, *arr, etc.) |
| `diskstation` | Alessandro | Synology DS218+ - Storage, Garage S3, backups |
| `nuc13` | root | Proxmox host - VMs and LXC containers |

### Accessing LXC Containers

```bash
# Via Proxmox host
ssh nuc13 "pct exec <VMID> -- <command>"

# Example: access exit-nordvpn-nl (VMID 200)
ssh nuc13 "pct exec 200 -- sh"
ssh nuc13 "pct exec 200 -- wg show"
```

## Directory Organization

Each Docker host has a symlink from `~/docker/compose` to the repo:

| Host | Compose Dir | Volume Dir |
|------|-------------|------------|
| raspberrypi5 | `~/docker/compose` → `~/homelab/docker/raspberrypi5` | `~/docker/volumes` |
| dockerhost | `~/docker/compose` → `~/homelab/docker/dockerhost` | `~/docker/volumes` |
| diskstation | `/volume1/docker/compose` → `~/homelab/docker/diskstation` | `/volume1/docker` |

Docker Compose files use these environment variables:
- `$COMPOSEDIR` - Path to compose files
- `$VOLUMEDIR` - Path to persistent volumes
- `$LOCAL_DOMAIN` - e.g., `home.alborworld.com`

## Secrets Management (SOPS + age)

All secrets are encrypted with SOPS using age encryption. Never commit unencrypted `.env` files.

### File Patterns

- `.env` - Decrypted secrets (git-ignored)
- `.env.sops.enc` - Encrypted secrets (committed)
- `.env.template` - Template showing required variables

### Makefile Targets

```bash
# Docker stacks
make decrypt-raspberrypi5    # Decrypt .env.sops.enc → .env
make encrypt-dockerhost      # Encrypt .env → .env.sops.enc
make show-diskstation        # Print decrypted .env to stdout
make deploy-raspberrypi5     # Deploy .env to remote host

# OpenTofu stacks
make tofu-decrypt STACK=cloudflare
make tofu-decrypt STACK=proxmox/tailscale-exit-nordvpn-nl
make tofu-encrypt STACK=garage
```

### Manual SOPS Commands

```bash
# Decrypt
sops --input-type dotenv --output-type dotenv --decrypt .env.sops.enc > .env

# Encrypt
sops --input-type dotenv --output-type dotenv --encrypt .env > .env.sops.enc

# Edit in-place
sops .env.sops.enc
```

## OpenTofu Stacks

Located in `tofu/`. Each stack has:
- `main.tf` - Resources
- `variables.tf` - Input variables
- `backend.tf` - S3 state backend (Garage)
- `.env.sops.enc` - Encrypted credentials

### Deploying a Stack

```bash
cd tofu/<stack>
make tofu-decrypt STACK=<stack>      # From repo root
source ../scripts/tofu-env.sh        # Load env vars
tofu init
tofu plan
tofu apply
rm .env                               # Cleanup
```

## Useful Commands

```bash
# Check container status on a host
ssh raspberrypi5 "docker ps"

# View logs
ssh dockerhost "docker logs <container> --tail 50"

# Restart a service
ssh raspberrypi5 "cd ~/docker/compose && docker compose restart <service>"

# Pull and update all services
ssh dockerhost "cd ~/docker/compose && docker compose pull && docker compose up -d"
```
