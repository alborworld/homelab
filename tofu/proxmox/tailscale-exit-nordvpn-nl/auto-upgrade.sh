#!/bin/sh
# Weekly auto-upgrade script for Alpine LXC
# Runs via /etc/periodic/weekly/

LOG_TAG="tailscale-exit-nordvpn-nl-upgrade"

logger -t "$LOG_TAG" "Starting weekly upgrade"

# Update and upgrade packages
apk update && apk upgrade

# Restart services to pick up updates
wg-quick down wg0 && wg-quick up wg0
ip rule add to 100.64.0.0/10 lookup 52 priority 5200 2>/dev/null || true
rc-service tailscale restart

logger -t "$LOG_TAG" "Weekly upgrade complete"