# exit-nl: Tailscale VPN Exit Node (Alpine LXC)

A dedicated Tailscale exit node that routes all traffic through NordVPN Amsterdam.

## Architecture

```
Client Device
    │
    ▼ (Tailscale)
┌─────────────────────────────┐
│  LXC: exit-nl (Alpine)      │
│                             │
│  tailscale0 ──► nftables    │
│                    │        │
│                    ▼        │
│                  wg0 ───────┼──► NordVPN NL
│                             │
│  Kill-switch: No egress     │
│  unless WireGuard is up     │
└─────────────────────────────┘
```

## Prerequisites

1. **NordVPN subscription** with WireGuard support
2. **Tailscale account** with admin access
3. **Proxmox VE** host

## Quick Start

### 1. Get Your Credentials

**NordVPN WireGuard key:**
1. Go to https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/
2. Click "Set up NordVPN manually"
3. Select "WireGuard"
4. Copy your private key

**Tailscale auth key:**
1. Go to https://login.tailscale.com/admin/settings/keys
2. Generate a new auth key (reusable, with exit node capability)

### 2. Create the LXC (on Proxmox host)

```bash
# Copy the script to Proxmox
scp create-lxc.sh root@proxmox:/tmp/

# SSH to Proxmox and run
ssh root@proxmox
cd /tmp
chmod +x create-lxc.sh

# Create with defaults (VMID 200, DHCP)
./create-lxc.sh

# Or customize
VMID=201 IP="10.0.4.201/24" GATEWAY="10.0.4.1" ./create-lxc.sh
```

### 3. Setup the Exit Node (inside LXC)

```bash
# Start and enter the LXC
pct start 200
pct enter 200

# Download and run setup
wget -O setup.sh https://raw.githubusercontent.com/YOUR_REPO/main/lxc/proxmox/exit-nl/setup.sh
chmod +x setup.sh

# Run with your credentials
WIREGUARD_PRIVATE_KEY="your-nordvpn-key" \
TAILSCALE_AUTHKEY="tskey-auth-xxxxx" \
./setup.sh
```

### 4. Approve the Exit Node

1. Go to https://login.tailscale.com/admin/machines
2. Find `exit-nl`
3. Click the three dots menu → "Edit route settings"
4. Enable "Use as exit node"

## Usage

### Select Exit Node on macOS

1. Click Tailscale menu bar icon
2. Select "Exit Node" → `exit-nl`

### Select Exit Node on iOS

1. Open Tailscale app
2. Tap "Exit Node"
3. Select `exit-nl`

### Verify VPN is Working

```bash
# On your client device
curl https://ipinfo.io
# Should show Netherlands / NordVPN IP
```

## Troubleshooting

### Inside the LXC

```bash
# WireGuard status
wg show

# Tailscale status
tailscale status

# Check public IP (should be NL)
curl --interface wg0 https://ipinfo.io

# View firewall rules
nft list ruleset

# Check services
rc-service wireguard status
rc-service tailscale status

# View logs
tail -f /var/log/messages | grep -E "(wireguard|tailscale|exit-nl)"

# Manual health check
/usr/local/bin/health-check.sh

# Restart services
rc-service wireguard restart
rc-service tailscale restart
```

### Common Issues

**WireGuard handshake failing:**
```bash
# Check if endpoint is reachable
ping -c 3 nl869.nordvpn.com

# Try a different NordVPN server
# Find servers:
curl -s "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_technologies\]\[identifier\]=wireguard_udp&filters\[country_id\]=153&limit=5" | jq -r '.[].hostname'
```

**Tailscale can't connect:**
```bash
# Check if Tailscale control plane is reachable
curl -I https://controlplane.tailscale.com

# Verify nftables allows Tailscale
nft list chain inet filter output | grep -E "(443|41641)"
```

**No internet through exit node:**
```bash
# Verify NAT is working
nft list chain inet nat postrouting

# Check IP forwarding
sysctl net.ipv4.ip_forward
```

## Maintenance

### Update Alpine Packages

```bash
apk update && apk upgrade
rc-service wireguard restart
rc-service tailscale restart
```

### Change NordVPN Server

```bash
# Edit WireGuard config
vi /etc/wireguard/wg0.conf
# Update Endpoint and PublicKey

# Restart
rc-service wireguard restart
```

### Backup

The LXC is backed up daily by PBS. To restore:
1. Proxmox GUI → Datacenter → Storage → PBS
2. Select backup → Restore

Or recreate from scratch using the scripts in this repo.

## Security Notes

- **Kill-switch**: The nftables rules block all internet egress unless WireGuard is up
- **Tailscale exemption**: Control plane traffic (HTTPS to Tailscale) is always allowed to prevent lockout
- **No inbound ports**: Only established connections and Tailscale/WireGuard UDP are allowed inbound
- **Privileged LXC**: Required for `/dev/net/tun` access; minimized attack surface via nftables

## Files

| File | Description |
|------|-------------|
| `create-lxc.sh` | Proxmox LXC creation script |
| `setup.sh` | Alpine setup script (run inside LXC) |
| `secrets.env.template` | Template for credentials |
