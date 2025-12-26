#!/bin/bash
# Proxmox LXC creation script for Alpine-based Tailscale VPN exit node
# Run this on your Proxmox host

set -euo pipefail

# Configuration
VMID="${VMID:-200}"
HOSTNAME="exit-nl"
TEMPLATE="alpine-3.21-default_20241217_amd64.tar.xz"
STORAGE="${STORAGE:-local-lvm}"
TEMPLATE_STORAGE="${TEMPLATE_STORAGE:-local}"
MEMORY=256
CORES=1
DISK_SIZE=4
BRIDGE="${BRIDGE:-vmbr0}"
IP="${IP:-dhcp}"  # Or set static: "10.0.4.200/24"
GATEWAY="${GATEWAY:-}"  # Required if using static IP

# Download template if not present
if ! pveam list "$TEMPLATE_STORAGE" | grep -q "$TEMPLATE"; then
    echo "Downloading Alpine template..."
    pveam download "$TEMPLATE_STORAGE" "$TEMPLATE"
fi

# Build network config
NET_CONFIG="name=eth0,bridge=${BRIDGE}"
if [ "$IP" = "dhcp" ]; then
    NET_CONFIG="${NET_CONFIG},ip=dhcp"
else
    NET_CONFIG="${NET_CONFIG},ip=${IP}"
    [ -n "$GATEWAY" ] && NET_CONFIG="${NET_CONFIG},gw=${GATEWAY}"
fi

# Create LXC
echo "Creating LXC ${VMID} (${HOSTNAME})..."
pct create "$VMID" "${TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" \
    --hostname "$HOSTNAME" \
    --memory "$MEMORY" \
    --cores "$CORES" \
    --rootfs "${STORAGE}:${DISK_SIZE}" \
    --net0 "$NET_CONFIG" \
    --unprivileged 0 \
    --features nesting=1 \
    --onboot 1 \
    --timezone Europe/Amsterdam

# Configure TUN device access for WireGuard/Tailscale
echo "Configuring TUN device access..."
cat >> "/etc/pve/lxc/${VMID}.conf" << 'EOF'
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
EOF

echo "LXC ${VMID} created successfully!"
echo ""
echo "Next steps:"
echo "  1. Start the LXC:  pct start ${VMID}"
echo "  2. Enter the LXC:  pct enter ${VMID}"
echo "  3. Run the setup script inside the LXC"
