#!/bin/sh
# Health check with auto-remediation for Tailscale Exit Node
# Runs every 5 minutes via cron

set -u

EXPECTED_COUNTRY="NL"
LOG_TAG="exit-nordvpn-nl"
STATE_DIR="/var/lib/health-check"
FAIL_COUNT_FILE="$STATE_DIR/vpn_fail_count"
MAX_VPN_FAILURES=3

mkdir -p "$STATE_DIR"

log() { logger -t "$LOG_TAG" "$*"; echo "$*"; }

# ------------------------------------------------------------------------------
# Checks
# ------------------------------------------------------------------------------

check_wireguard() {
    if ! wg show wg0 >/dev/null 2>&1; then
        return 1
    fi
    HANDSHAKE=$(wg show wg0 latest-handshakes 2>/dev/null | awk '{print $2}')
    [ -z "$HANDSHAKE" ] && return 1
    NOW=$(date +%s)
    AGE=$((NOW - HANDSHAKE))
    # Handshake should be less than 3 minutes old
    [ "$AGE" -lt 180 ]
}

check_vpn_ip() {
    COUNTRY=$(curl -sf --max-time 5 https://ipinfo.io/country 2>/dev/null | tr -d '\n\r')
    [ "$COUNTRY" = "$EXPECTED_COUNTRY" ]
}

check_tailscale() {
    tailscale status >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# Remediation
# ------------------------------------------------------------------------------

restart_wireguard() {
    log "HEAL: Restarting WireGuard..."
    wg-quick down wg0 2>/dev/null || true
    sleep 2
    wg-quick up wg0
    # Re-add Tailscale routing fix
    ip rule add to 100.64.0.0/10 lookup 52 priority 5200 2>/dev/null || true
    sleep 3
}

restart_tailscale() {
    log "HEAL: Restarting Tailscale..."
    rc-service tailscale restart
    sleep 3
    # Re-authenticate if needed
    if ! tailscale status >/dev/null 2>&1; then
        log "HEAL: Tailscale still down after restart"
    fi
}

rotate_vpn_server() {
    log "HEAL: Rotating to new NordVPN server..."

    # Get a new recommended NL server
    NEW_SERVER=$(curl -sf --max-time 10 \
        "https://api.nordvpn.com/v1/servers/recommendations?filters%5Bservers_technologies%5D%5Bidentifier%5D=wireguard_udp&filters%5Bcountry_id%5D=153&limit=5" \
        2>/dev/null | jq -r '.[0].hostname + ":" + (.technologies[] | select(.identifier=="wireguard_udp") | .metadata[] | select(.name=="public_key") | .value)' 2>/dev/null | head -1)

    if [ -z "$NEW_SERVER" ]; then
        log "HEAL: Failed to get new server from NordVPN API"
        return 1
    fi

    NEW_HOST=$(echo "$NEW_SERVER" | cut -d: -f1)
    NEW_KEY=$(echo "$NEW_SERVER" | cut -d: -f2)

    if [ -z "$NEW_HOST" ] || [ -z "$NEW_KEY" ]; then
        log "HEAL: Invalid server response"
        return 1
    fi

    log "HEAL: Switching to $NEW_HOST"

    # Update WireGuard config
    wg-quick down wg0 2>/dev/null || true

    # Get current endpoint port (usually 51820)
    OLD_ENDPOINT=$(grep "^Endpoint" /etc/wireguard/wg0.conf | cut -d= -f2 | tr -d ' ')
    OLD_PORT=$(echo "$OLD_ENDPOINT" | cut -d: -f2)
    [ -z "$OLD_PORT" ] && OLD_PORT="51820"

    # Update config file
    sed -i "s|^Endpoint.*|Endpoint = ${NEW_HOST}:${OLD_PORT}|" /etc/wireguard/wg0.conf
    sed -i "s|^PublicKey.*|PublicKey = ${NEW_KEY}|" /etc/wireguard/wg0.conf

    wg-quick up wg0
    ip rule add to 100.64.0.0/10 lookup 52 priority 5200 2>/dev/null || true
    sleep 5

    # Reset fail counter
    echo 0 > "$FAIL_COUNT_FILE"

    log "HEAL: Rotated to $NEW_HOST"
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

FAILED=""
HEALED=""

# Check WireGuard
if ! check_wireguard; then
    log "FAIL: WireGuard tunnel down or stale handshake"
    restart_wireguard
    if check_wireguard; then
        HEALED="${HEALED}wireguard "
    else
        FAILED="${FAILED}wireguard "
    fi
fi

# Check VPN IP (only if WireGuard is up)
if [ -z "$FAILED" ] || ! echo "$FAILED" | grep -q "wireguard"; then
    if ! check_vpn_ip; then
        log "FAIL: Public IP not via NordVPN NL (got: $COUNTRY)"

        # Track consecutive failures
        FAIL_COUNT=$(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo 0)
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "$FAIL_COUNT" > "$FAIL_COUNT_FILE"

        if [ "$FAIL_COUNT" -ge "$MAX_VPN_FAILURES" ]; then
            log "FAIL: VPN IP check failed $FAIL_COUNT times, rotating server"
            rotate_vpn_server
            if check_vpn_ip; then
                HEALED="${HEALED}vpn-server "
            else
                FAILED="${FAILED}vpn-ip "
            fi
        else
            log "WARN: VPN IP check failed ($FAIL_COUNT/$MAX_VPN_FAILURES before rotation)"
            # Try simple restart first
            restart_wireguard
            if check_vpn_ip; then
                HEALED="${HEALED}vpn-ip "
                echo 0 > "$FAIL_COUNT_FILE"
            else
                FAILED="${FAILED}vpn-ip "
            fi
        fi
    else
        # Reset counter on success
        echo 0 > "$FAIL_COUNT_FILE" 2>/dev/null || true
    fi
fi

# Check Tailscale
if ! check_tailscale; then
    log "FAIL: Tailscale not connected"
    restart_tailscale
    if check_tailscale; then
        HEALED="${HEALED}tailscale "
    else
        FAILED="${FAILED}tailscale "
    fi
fi

# Report status
if [ -n "$HEALED" ]; then
    log "HEALED: ${HEALED}"
fi

if [ -n "$FAILED" ]; then
    log "CRITICAL: Health check FAILED after remediation: ${FAILED}"
    exit 1
fi

log "OK"
exit 0
