#!/bin/sh
# Setup script for Tailscale Exit Node via NordVPN
# Idempotent - safe to run multiple times
set -e

TAILSCALE_AUTHKEY="${1:-}"
HOSTNAME="exit-nordvpn-nl"

log() { echo "[setup] $*"; }

# ------------------------------------------------------------------------------
# Packages
# ------------------------------------------------------------------------------
log "Installing packages..."
apk update
apk add --no-cache wireguard-tools tailscale nftables curl jq

# ------------------------------------------------------------------------------
# IP Forwarding
# ------------------------------------------------------------------------------
log "Configuring IP forwarding..."
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/99-forwarding.conf << 'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sysctl -p /etc/sysctl.d/99-forwarding.conf 2>/dev/null || true

# ------------------------------------------------------------------------------
# WireGuard (config must be pre-copied to /etc/wireguard/wg0.conf)
# ------------------------------------------------------------------------------
log "Configuring WireGuard..."
chmod 600 /etc/wireguard/wg0.conf 2>/dev/null || true

# ------------------------------------------------------------------------------
# nftables (config must be pre-copied to /etc/nftables.d/exit-node.nft)
# ------------------------------------------------------------------------------
log "Configuring nftables..."
mkdir -p /etc/nftables.d
cat > /etc/nftables.conf << 'EOF'
#!/usr/sbin/nft -f
flush ruleset
include "/etc/nftables.d/*.nft"
EOF

# ------------------------------------------------------------------------------
# Health check (every 5 minutes)
# ------------------------------------------------------------------------------
log "Configuring health check..."
mkdir -p /usr/local/bin /etc/periodic/5min
chmod +x /usr/local/bin/health-check.sh 2>/dev/null || true
cat > /etc/periodic/5min/health-check << 'EOF'
#!/bin/sh
/usr/local/bin/health-check.sh
EOF
chmod +x /etc/periodic/5min/health-check
grep -q "periodic/5min" /etc/crontabs/root 2>/dev/null || \
  echo "*/5 * * * * run-parts /etc/periodic/5min" >> /etc/crontabs/root

# ------------------------------------------------------------------------------
# Auto-upgrade (weekly)
# ------------------------------------------------------------------------------
log "Configuring auto-upgrade..."
chmod +x /etc/periodic/weekly/auto-upgrade 2>/dev/null || true

# ------------------------------------------------------------------------------
# WireGuard boot script (with Tailscale routing fix)
# ------------------------------------------------------------------------------
log "Configuring WireGuard boot script..."
cat > /etc/local.d/wireguard.start << 'EOF'
#!/bin/sh
wg-quick up wg0
# Fix: Tailscale IPs must use table 52, not wg-quick's table 51820
ip rule add to 100.64.0.0/10 lookup 52 priority 5200 2>/dev/null || true
EOF
chmod +x /etc/local.d/wireguard.start

# ------------------------------------------------------------------------------
# Enable services
# ------------------------------------------------------------------------------
log "Enabling services..."
rc-update add sysctl boot 2>/dev/null || true
rc-update add nftables boot 2>/dev/null || true
rc-update add tailscale default 2>/dev/null || true
rc-update add crond default 2>/dev/null || true
rc-update add local default 2>/dev/null || true

# ------------------------------------------------------------------------------
# Start services (order matters: WireGuard before nftables)
# ------------------------------------------------------------------------------
log "Starting services..."

# WireGuard
if ! wg show wg0 >/dev/null 2>&1; then
  wg-quick up wg0
  ip rule add to 100.64.0.0/10 lookup 52 priority 5200 2>/dev/null || true
fi

# Wait for WireGuard handshake
log "Waiting for WireGuard handshake..."
for i in 1 2 3 4 5; do
  if wg show wg0 latest-handshakes | grep -q "[0-9]"; then
    HANDSHAKE=$(wg show wg0 latest-handshakes | awk '{print $2}')
    if [ "$HANDSHAKE" -gt 0 ] 2>/dev/null; then
      log "WireGuard connected"
      break
    fi
  fi
  sleep 2
done

# nftables
rc-service nftables start 2>/dev/null || rc-service nftables restart

# Tailscale
rc-service tailscale start 2>/dev/null || true

# Wait for tailscaled
log "Waiting for Tailscale daemon..."
for i in 1 2 3 4 5; do
  if tailscale status >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# Authenticate Tailscale
if [ -n "$TAILSCALE_AUTHKEY" ]; then
  log "Authenticating Tailscale..."
  tailscale up \
    --authkey="$TAILSCALE_AUTHKEY" \
    --hostname="$HOSTNAME" \
    --advertise-exit-node \
    --accept-routes=false \
    --accept-dns=false
fi

# Crond
rc-service crond start 2>/dev/null || true

# ------------------------------------------------------------------------------
# Verify
# ------------------------------------------------------------------------------
log "Verifying setup..."
echo "  WireGuard: $(wg show wg0 >/dev/null 2>&1 && echo 'OK' || echo 'FAIL')"
echo "  Tailscale: $(tailscale status >/dev/null 2>&1 && echo 'OK' || echo 'FAIL')"
echo "  Exit IP:   $(curl -sf --max-time 5 https://ipinfo.io/city 2>/dev/null || echo 'unknown')"

log "Setup complete"
