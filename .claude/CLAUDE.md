# Homelab Repository Guidelines

## Issue Tracking: Use Beads
This project uses **beads** (`bd`) for all issue tracking.

### Required Workflow
Before starting any work:
1. Check for ready work:
   `bd ready`
2. Pick a task and claim it:
   `bd update <issue-id> --status=in_progress`
3. Work on the task (code, tests, docs)
4. When done, close it:
   `bd close <issue-id>`

### Creating New Issues
If you discover new work while implementing:
`bd create --title="Issue title" --type=task|bug|feature --priority=2`

### Rules
- ALWAYS check `bd ready` before asking "what should I work on?"
- ALWAYS update issue status to `in_progress` when you start working
- ALWAYS close issues when you complete them
- NEVER use markdown TODO lists for tracking work

## Session Completion
When ending a work session:
1. Create beads issues for remaining work (`bd create`)
2. Close finished tasks (`bd close`), update in-progress items
3. Run `bd sync` and commit changes
5. Push to remote if on a feature branch (confirm with user before pushing to main)
6. Provide context for next session

## Committing
- Check changes with `git diff`
- Commits must be GPG-signed (verified)
- Single-line commit messages with conventional commits format
- No Claude attributions
- Breaking changes: use `!` after the type/scope, before the colon (e.g. `feat!:` or `feat(scope)!:`) and add a second line explaining what breaks

## SSH Host Access

All hosts are configured in `~/.ssh/config`:

| Host           | User       | Description                                            |
|----------------|------------|--------------------------------------------------------|
| `raspberrypi5` | pi         | Edge node - Homepage, AdGuard, Traefik, Home Assistant |
| `dockerhost`   | albor      | Proxmox VM - Media stack (Plex, *arr, etc.)            |
| `diskstation`  | Alessandro | Synology DS218+ - Storage, Garage S3, backups          |
| `nuc13`        | root       | Proxmox host - VMs and LXC containers                  |

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

| Host         | Compose Dir                                                | Volume Dir         |
|--------------|------------------------------------------------------------|--------------------|
| raspberrypi5 | `~/docker/compose` → `~/homelab/docker/raspberrypi5`       | `~/docker/volumes` |
| dockerhost   | `~/docker/compose` → `~/homelab/docker/dockerhost`         | `~/docker/volumes` |
| diskstation  | `/volume1/docker/compose` → `~/homelab/docker/diskstation` | `/volume1/docker`  |

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

## Tailscale VPN

All hosts connected via Tailscale mesh. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#tailscale-vpn) for full details.

Key IPs:
- `100.77.35.97` - raspberrypi5 (AdGuard, exit node)
- `100.68.31.112` - diskstation (AdGuard replica)
- `100.90.91.69` - exit-nordvpn-nl (NordVPN exit)

```bash
tailscale set --exit-node=exit-nordvpn-nl  # Use NordVPN
tailscale set --exit-node=                  # Disable exit
tailscale status                            # Check status
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
