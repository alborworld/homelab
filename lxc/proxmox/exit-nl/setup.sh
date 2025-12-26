#!/bin/sh
# Alpine setup script for Tailscale VPN exit node
# Run this INSIDE the LXC after creation

set -eu

# ============================================================================
# CONFIGURATION - Edit these values
# ============================================================================
# Get your NordVPN WireGuard private key from:
# https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/
# Under "Set up NordVPN manually" > "WireGuard" > Copy private key
WIREGUARD_PRIVATE_KEY="${WIREGUARD_PRIVATE_KEY:-}"

# NordVPN Amsterdam server (get latest from NordVPN API or use this default)
# Find servers: curl -s "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_technologies\]\[identifier\]=wireguard_udp&filters\[country_id\]=153" | jq '.[0]'
NORDVPN_ENDPOINT="${NORDVPN_ENDPOINT:-nl869.nordvpn.com:51820}"
NORDVPN_PUBLIC_KEY="${NORDVPN_PUBLIC_KEY:-T3Y5wHpSHgCk1MhryRgkrCOCY729qfGPrVnvzwXsFz0=}"

# Tailscale auth key (get from https://login.tailscale.com/admin/settings/keys)
TAILSCALE_AUTHKEY="${TAILSCALE_AUTHKEY:-}"

# ============================================================================
# VALIDATION
# ============================================================================
if [ -z "$WIREGUARD_PRIVATE_KEY" ]; then
    echo "ERROR: WIREGUARD_PRIVATE_KEY is required"
    echo "Get it from: https://my.nordaccount.com/dashboard/nordvpn/manual-configuration/"
    exit 1
fi

if [ -z "$TAILSCALE_AUTHKEY" ]; then
    echo "ERROR: TAILSCALE_AUTHKEY is required"
    echo "Get it from: https://login.tailscale.com/admin/settings/keys"
    exit 1
fi

echo "==> Updating system..."
apk update && apk upgrade

echo "==> Installing packages..."
apk add --no-cache \
    wireguard-tools \
    tailscale \
    nftables \
    curl \
    jq \
    openrc

echo "==> Enabling IP forwarding..."
cat > /etc/sysctl.d/99-forwarding.conf << 'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p /etc/sysctl.d/99-forwarding.conf

echo "==> Creating WireGuard configuration..."
mkdir -p /etc/wireguard
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = ${WIREGUARD_PRIVATE_KEY}
Address = 10.5.0.2/32
DNS = 103.86.96.100, 103.86.99.100

[Peer]
PublicKey = ${NORDVPN_PUBLIC_KEY}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${NORDVPN_ENDPOINT}
PersistentKeepalive = 25
EOF
chmod 600 /etc/wireguard/wg0.conf

echo "==> Configuring nftables kill-switch..."
cat > /etc/nftables.d/exit-node.nft << 'EOF'
#!/usr/sbin/nft -f

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        # Allow established/related
        ct state established,related accept

        # Allow loopback
        iif "lo" accept

        # Allow ICMP/ICMPv6
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        # Allow Tailscale (UDP 41641 default, but it can vary)
        udp dport 41641 accept

        # Allow WireGuard from NordVPN
        udp dport 51820 accept

        # Allow from Tailscale interface
        iifname "tailscale0" accept

        # Allow from LAN (for initial setup/SSH)
        ip saddr 10.0.0.0/8 tcp dport 22 accept
    }

    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow established/related
        ct state established,related accept

        # Allow Tailscale -> WireGuard (VPN egress)
        iifname "tailscale0" oifname "wg0" accept

        # Allow WireGuard -> Tailscale (return traffic)
        iifname "wg0" oifname "tailscale0" accept
    }

    chain output {
        type filter hook output priority 0; policy drop;

        # Allow established/related
        ct state established,related accept

        # Allow loopback
        oif "lo" accept

        # Allow ICMP/ICMPv6
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        # Allow DNS (for initial resolution)
        udp dport 53 accept
        tcp dport 53 accept

        # Allow Tailscale control plane (HTTPS to Tailscale servers)
        tcp dport 443 ip daddr {
            100.64.0.0/10,    # Tailscale CGNAT range
            104.18.0.0/16,    # Cloudflare (controlplane.tailscale.com)
            172.67.0.0/16     # Cloudflare
        } accept

        # Allow Tailscale UDP (DERP and direct connections)
        udp dport { 41641, 3478 } accept

        # Allow WireGuard to NordVPN
        udp dport 51820 accept

        # Allow everything through WireGuard tunnel
        oifname "wg0" accept

        # Allow to Tailscale interface
        oifname "tailscale0" accept
    }
}

table inet nat {
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;

        # NAT Tailscale traffic through WireGuard
        oifname "wg0" masquerade
    }
}
EOF

mkdir -p /etc/nftables.d
cat > /etc/nftables.conf << 'EOF'
#!/usr/sbin/nft -f
flush ruleset
include "/etc/nftables.d/*.nft"
EOF

echo "==> Creating health check script..."
cat > /usr/local/bin/health-check.sh << 'HEALTHEOF'
#!/bin/sh
# Health check for VPN exit node

EXPECTED_COUNTRY="NL"
LOG_TAG="exit-nl-health"

check_wireguard() {
    if wg show wg0 >/dev/null 2>&1; then
        HANDSHAKE=$(wg show wg0 latest-handshakes | awk '{print $2}')
        NOW=$(date +%s)
        AGE=$((NOW - HANDSHAKE))
        if [ "$AGE" -lt 180 ]; then
            return 0
        fi
    fi
    return 1
}

check_vpn_ip() {
    COUNTRY=$(curl -sf --max-time 5 --interface wg0 https://ipinfo.io/country 2>/dev/null | tr -d '\n')
    [ "$COUNTRY" = "$EXPECTED_COUNTRY" ]
}

check_tailscale() {
    tailscale status >/dev/null 2>&1
}

# Run checks
FAILED=""

if ! check_wireguard; then
    FAILED="${FAILED}wireguard "
    logger -t "$LOG_TAG" "FAIL: WireGuard tunnel down or stale"
fi

if ! check_vpn_ip; then
    FAILED="${FAILED}vpn-ip "
    logger -t "$LOG_TAG" "FAIL: Public IP not via NordVPN NL"
fi

if ! check_tailscale; then
    FAILED="${FAILED}tailscale "
    logger -t "$LOG_TAG" "FAIL: Tailscale not connected"
fi

if [ -n "$FAILED" ]; then
    logger -t "$LOG_TAG" "Health check FAILED: ${FAILED}"
    exit 1
fi

logger -t "$LOG_TAG" "Health check OK"
exit 0
HEALTHEOF
chmod +x /usr/local/bin/health-check.sh

echo "==> Setting up health check cron..."
cat > /etc/periodic/5min/health-check << 'EOF'
#!/bin/sh
/usr/local/bin/health-check.sh
EOF
chmod +x /etc/periodic/5min/health-check

# Create 5min periodic directory runner if it doesn't exist
mkdir -p /etc/periodic/5min
grep -q "periodic/5min" /etc/crontabs/root 2>/dev/null || \
    echo "*/5 * * * * run-parts /etc/periodic/5min" >> /etc/crontabs/root

echo "==> Enabling services..."
rc-update add nftables boot
rc-update add wireguard boot
rc-update add tailscale default
rc-update add crond default

echo "==> Starting nftables..."
rc-service nftables start

echo "==> Starting WireGuard..."
ln -sf /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf
rc-service wireguard start

# Wait for WireGuard to establish
echo "==> Waiting for WireGuard tunnel..."
sleep 5

echo "==> Starting Tailscale..."
rc-service tailscale start
sleep 2

echo "==> Authenticating Tailscale as exit node..."
tailscale up \
    --authkey="$TAILSCALE_AUTHKEY" \
    --hostname=exit-nl \
    --advertise-exit-node \
    --accept-routes=false \
    --accept-dns=false

echo "==> Starting cron for health checks..."
rc-service crond start

echo ""
echo "============================================"
echo "Setup complete!"
echo "============================================"
echo ""
echo "Verification commands:"
echo "  wg show                    # WireGuard status"
echo "  tailscale status           # Tailscale status"
echo "  curl https://ipinfo.io     # Should show NL"
echo "  nft list ruleset           # Firewall rules"
echo "  /usr/local/bin/health-check.sh  # Manual health check"
echo ""
echo "IMPORTANT: Approve the exit node in Tailscale admin console:"
echo "  https://login.tailscale.com/admin/machines"
echo ""
