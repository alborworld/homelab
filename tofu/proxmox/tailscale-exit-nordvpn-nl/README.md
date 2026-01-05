# Tailscale Exit Node via NordVPN Amsterdam

Alpine LXC container that acts as a Tailscale exit node, routing all traffic through NordVPN Netherlands.

## Architecture

```
                      ┌─────────────────────────────────────────┐
                      │          DEPLOYMENT FLOW                │
                      └─────────────────────────────────────────┘
                                       │
              ┌────────────────────────┼────────────────────────┐
              ▼                        ▼                        ▼
      ┌───────────────┐      ┌─────────────────┐      ┌─────────────────┐
      │   OpenTofu    │      │     Ansible     │      │   Auto-heal     │
      │ (infra only)  │ ───► │  (provisioning) │ ───► │   (runtime)     │
      └───────────────┘      └─────────────────┘      └─────────────────┘
      • LXC container        • Packages              • Health check
      • TUN device           • WireGuard             • Server rotation
      • SSH bootstrap        • nftables              • Service restart
                             • Tailscale
                             • Cron jobs

                      ┌─────────────────────────────────────────┐
                      │          TRAFFIC FLOW                   │
                      └─────────────────────────────────────────┘

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
- **Declarative:** OpenTofu for infra, Ansible for config (idempotent, diffable)

## Prerequisites

1. Proxmox VE with SSH access (host `nuc13`)
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

### 2. Create LXC with OpenTofu

```bash
cd tofu/proxmox/tailscale-exit-nordvpn-nl

# Decrypt secrets (or create from .env.template)
make tofu-decrypt STACK=proxmox/tailscale-exit-nordvpn-nl

# Deploy
source ../../scripts/tofu-env.sh
tofu init
tofu plan
tofu apply

# Cleanup
rm .env
```

This creates:
- Alpine LXC container (VMID 200)
- TUN device access for WireGuard/Tailscale
- SSH access for Ansible

### 3. Provision with Ansible

```bash
cd ansible

# Create secrets file
cp secrets.yml.template secrets.yml
# Edit secrets.yml with wireguard_private_key and tailscale_authkey

# Optionally encrypt with ansible-vault
ansible-vault encrypt secrets.yml

# Run playbook
ansible-playbook playbooks/exit-node-nordvpn.yml -e @secrets.yml
# Or if vault-encrypted:
ansible-playbook playbooks/exit-node-nordvpn.yml -e @secrets.yml --ask-vault-pass
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

### OpenTofu (this directory)

| File | Description |
|------|-------------|
| `main.tf` | LXC container + TUN config + SSH bootstrap |
| `provider.tf` | Proxmox provider config |
| `backend.tf` | S3 state backend (Garage) |
| `variables.tf` | Input variables |
| `.env.template` | Environment template |

### Ansible (`ansible/`)

| File | Description |
|------|-------------|
| `roles/exit_node_nordvpn/` | Provisioning role |
| `playbooks/exit-node-nordvpn.yml` | Main playbook |
| `inventory.yml` | Host inventory |
| `secrets.yml.template` | Secrets template |

## Operations

### Health Check & Auto-healing

```bash
# SSH into container
ssh exit-nordvpn-nl  # via Tailscale
# or
ssh nuc13 "pct exec 200 -- sh"

# Run health check manually
/usr/local/bin/health-check.sh

# Watch auto-healing logs
tail -f /var/log/messages | grep exit-nordvpn-nl

# Check VPN failure counter (rotates server after 3 failures)
cat /var/lib/health-check/vpn_fail_count
```

### Manual Verification

```bash
wg show                      # WireGuard status
tailscale status             # Tailscale status
curl https://ipinfo.io       # Should show NL
nft list ruleset             # Firewall rules
```

### Re-provision with Ansible

```bash
cd ansible
ansible-playbook playbooks/exit-node-nordvpn.yml -e @secrets.yml
```

### Change NordVPN Server

Update `ansible/inventory.yml`:

```yaml
exit-nordvpn-nl:
  nordvpn_endpoint: "nl1234.nordvpn.com:51820"
  nordvpn_public_key: "new-public-key="
```

Then re-run Ansible:

```bash
ansible-playbook playbooks/exit-node-nordvpn.yml -e @secrets.yml
```

Find NL servers:
```bash
curl -s "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_technologies\]\[identifier\]=wireguard_udp&filters\[country_id\]=153&limit=5" | jq -r '.[] | .hostname + " " + (.technologies[] | select(.identifier=="wireguard_udp") | .metadata[] | select(.name=="public_key") | .value)'
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
wg show
# Check if endpoint is reachable
ping -c 3 $(grep Endpoint /etc/wireguard/wg0.conf | cut -d= -f2 | cut -d: -f1 | tr -d ' ')
```

### Tailscale not connecting

```bash
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
nft flush ruleset
# Then fix the issue and restart nftables
rc-service nftables restart
```

### Ansible can't connect

```bash
# Verify SSH access
ssh -o StrictHostKeyChecking=no root@exit-nordvpn-nl

# If using Tailscale hostname, ensure your machine has Tailscale running
tailscale status
```
