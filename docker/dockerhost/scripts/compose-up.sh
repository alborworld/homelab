#!/bin/bash
# Boot-time startup script for the dockerhost compose stack.
# Called by docker-compose-up.service after Docker is ready.
#
# Why this exists:
# When the NUC13 powers off nightly and the VM restarts at 6:15am,
# Docker restores containers via restart policies. But containers using
# network_mode: "service:gluetun" hold a reference to Gluetun's old
# container ID. The old ID no longer exists after restart, so they fail
# with exit 128 ("joining network namespace of container: No such container").
# Docker's restart policy just re-starts the broken container — it cannot
# recreate the network namespace link. Only `docker compose up -d` can
# recreate containers with the correct reference.
#
# Additionally, Gluetun's VPN may take time to connect (cycling through
# servers), so dependent services can fail on the first attempt. This
# script retries until all services are running.

set -uo pipefail

COMPOSE_DIR=/home/albor/docker/compose
MAX_RETRIES=5
RETRY_DELAY=30

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cd "$COMPOSE_DIR"

for attempt in $(seq 1 "$MAX_RETRIES"); do
    log "Attempt $attempt/$MAX_RETRIES: docker compose up -d"

    # docker compose up -d exits non-zero if a dependency isn't healthy yet,
    # but it still starts everything it can. We check actual state afterwards.
    docker compose up -d 2>&1 || true

    sleep 5

    # Count containers that aren't running
    NOT_RUNNING=$(docker compose ps -a --format '{{.State}}' 2>/dev/null \
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

# Log which services are still not running
log "WARNING: Some services still not running after $MAX_RETRIES attempts:"
docker compose ps -a --format "table {{.Name}}\t{{.Status}}" 2>&1 | grep -v "running" || true
exit 1
