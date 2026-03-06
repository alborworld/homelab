#!/bin/bash
# Boot-time startup script for the diskstation compose stack.
# Called by /usr/local/etc/rc.d/compose-up.sh on Synology boot.
#
# On Synology NAS, Docker's restart policies don't always bring up
# all containers after a reboot. This script ensures all services
# are properly started via docker compose up -d with retry logic.

set -uo pipefail

COMPOSE_DIR=/volume1/docker/compose
DOCKER=/usr/local/bin/docker
MAX_RETRIES=5
RETRY_DELAY=30

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cd "$COMPOSE_DIR"

for attempt in $(seq 1 "$MAX_RETRIES"); do
    log "Attempt $attempt/$MAX_RETRIES: docker compose up -d"

    $DOCKER compose up -d 2>&1 || true

    sleep 5

    NOT_RUNNING=$($DOCKER compose ps -a --format '{{.State}}' 2>/dev/null \
        | grep -cv running || true)

    if [ "$NOT_RUNNING" -eq 0 ]; then
        log "All services running."
        exit 0
    fi

    log "$NOT_RUNNING service(s) not running yet."

    if [ "$attempt" -lt "$MAX_RETRIES" ]; then
        log "Waiting ${RETRY_DELAY}s before retry..."
        sleep "$RETRY_DELAY"
    fi
done

log "WARNING: Some services still not running after $MAX_RETRIES attempts:"
$DOCKER compose ps -a --format "table {{.Name}}\t{{.Status}}" 2>&1 | grep -v "running" || true
exit 1
