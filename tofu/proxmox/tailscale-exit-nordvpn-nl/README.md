# Tailscale Exit Node via NordVPN Amsterdam

Alpine LXC container that acts as a Tailscale exit node, routing all traffic through NordVPN Netherlands.

## Architecture

```
Client Device
    │
    ▼ (Tailscale)
┌─────────────────────────────────────┐
│  LXC: exit-nordvpn-nl (Alpine)      │
│                                     │
│  tailscale0 ──► nftables ──► wg0 ───┼──► NordVPN NL
│                (kill-switch)        │
└─────────────────────────────────────┘
```

## Features

- **Kill-switch:** nftables blocks all egress unless WireGuard is up
- **Auto-healing:** Every 5 minutes, verifies and auto-repairs:
  - WireGuard tunnel down or stale → restart
  - Tailscale disconnected → restart
  - Wrong VPN exit IP (3x failures) → rotate to new NordVPN server
- **Auto-upgrades:** Weekly Alpine package updates with service restart
- **Tailscale exemption:** Control plane traffic always allowed (prevents lockout)

## Prerequisites

1. Proxmox VE with SSH access
2. NordVPN subscription with WireGuard support
3. Tailscale account
4. Garage S3 credentials for state backend

## Quick Start

### 1. Get Credentials

**NordVPN WireGuard:**
1. Go to https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/
2. Click "Set up NordVPN manually" → "WireGuard"
3. Copy your private key

**Tailscale:**
1. Go to https://login.tailscale.com/admin/settings/keys
2. Create a reusable auth key with exit node capability

**Proxmox:**
- API endpoint (e.g., `https://pve.home.alborworld.com`)
- API token (create in PVE: Datacenter → Permissions → API Tokens)

### 2. Setup Environment

```bash
cd tofu/proxmox/tailscale-exit-nordvpn-nl

# Copy and fill in template
cp .env.template .env
# Edit .env with your credentials

# Encrypt with sops (from repo root)
cd ../../..
sops --input-type dotenv --output-type dotenv --encrypt \
  tofu/proxmox/tailscale-exit-nordvpn-nl/.env > \
  tofu/proxmox/tailscale-exit-nordvpn-nl/.env.sops.enc

# Remove unencrypted file
rm tofu/proxmox/tailscale-exit-nordvpn-nl/.env
```

### 3. Deploy

```bash
cd tofu/proxmox/tailscale-exit-nordvpn-nl

# Decrypt secrets
sops --input-type dotenv --output-type dotenv --decrypt .env.sops.enc > .env

# Source environment
source ../../scripts/tofu-env.sh

# Deploy
tofu init
tofu plan
tofu apply

# Cleanup
rm .env
```

### 4. Approve Exit Node

1. Go to https://login.tailscale.com/admin/machines
2. Find `exit-nordvpn-nl`
3. Click ⋮ → "Edit route settings"
4. Enable "Use as exit node"

### 5. Use the Exit Node

**macOS:** Tailscale menu → Exit Node → `exit-nordvpn-nl`

**iOS:** Tailscale app → Exit Node → `exit-nordvpn-nl`

**Verify:** `curl https://ipinfo.io` should show Netherlands

## Files

| File | Description |
|------|-------------|
| `main.tf` | LXC container and provisioning |
| `setup.sh` | Idempotent container setup (packages, services, config) |
| `provider.tf` | Proxmox provider config |
| `backend.tf` | S3 state backend (Garage) |
| `variables.tf` | Input variables |
| `wireguard.conf.tpl` | WireGuard config template |
| `nftables.nft` | Firewall rules (kill-switch) |
| `health-check.sh` | Health check script (5-min cron) |
| `auto-upgrade.sh` | Weekly upgrade script |
| `.env.template` | Environment template |

## Operations

### Health Check & Auto-healing

```bash
# SSH into container
pct enter 200

# Run health check manually
/usr/local/bin/health-check.sh

# Watch auto-healing logs
tail -f /var/log/messages | grep exit-nordvpn-nl

# Check VPN failure counter (rotates server after 3 failures)
cat /var/lib/health-check/vpn_fail_count
```

### Manual Verification

```bash
# Inside container
wg show                      # WireGuard status
tailscale status             # Tailscale status
curl https://ipinfo.io       # Should show NL
nft list ruleset             # Firewall rules
```

### Upgrades

Auto-upgrades run weekly. For manual upgrade:

```bash
pct enter 200
apk update && apk upgrade
wg-quick down wg0 && wg-quick up wg0
ip rule add to 100.64.0.0/10 lookup 52 priority 5200 2>/dev/null || true
rc-service tailscale restart
```

### Re-provision

The `setup.sh` script is idempotent. To re-run without destroying the container:

```bash
# From repo root
cat tofu/proxmox/tailscale-exit-nordvpn-nl/setup.sh | \
  ssh nuc13 "cat > /tmp/setup.sh && pct push 200 /tmp/setup.sh /tmp/setup.sh && pct exec 200 -- sh /tmp/setup.sh"
```

### Change NordVPN Server

Edit `variables.tf` defaults or override in `.env`:

```bash
# Find NL servers
curl -s "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_technologies\]\[identifier\]=wireguard_udp&filters\[country_id\]=153&limit=5" | jq -r '.[].hostname'

# Update and apply
tofu apply
```

## Technical Details

### Routing Fix

When using `wg-quick`, it creates policy routing rules that route all traffic through the WireGuard tunnel:

```
5209: not from all fwmark 0xca6c lookup 51820  → default dev wg0
```

This conflicts with Tailscale exit node traffic. Return packets destined for Tailscale clients (100.64.0.0/10) get sent through wg0 instead of tailscale0.

**Fix:** Add a higher-priority rule to route Tailscale IPs via Tailscale's routing table:

```bash
ip rule add to 100.64.0.0/10 lookup 52 priority 5200
```

This rule is added at boot via `/etc/local.d/wireguard.start` and must be re-added after any WireGuard restart.

## Troubleshooting

### WireGuard not connecting

```bash
pct enter 200
wg show
# Check if endpoint is reachable (get hostname from wg show output)
```

### Tailscale not connecting

```bash
pct enter 200
tailscale status
curl -I https://controlplane.tailscale.com
```

### Container won't start

```bash
# On Proxmox host
pct config 200
pct start 200
journalctl -u pve-container@200
```

### Kill-switch blocking everything

```bash
# Temporarily disable (emergency only)
pct enter 200
nft flush ruleset
# Then fix the issue and restart nftables
rc-service nftables restart
```