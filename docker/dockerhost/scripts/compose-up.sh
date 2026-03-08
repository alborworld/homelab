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
# Strategy: phased startup to avoid resource contention and race conditions.
#   Phase 1: Start non-VPN services normally (no force-recreate needed)
#   Phase 2: Force-recreate Gluetun stack to fix stale network namespaces
#   Phase 3: Start any remaining "Created" containers
#
# The Gluetun group needs --force-recreate because Docker's restart policy
# may have already started containers with stale network namespace
# references. Those containers appear "running" but have broken networking.

set -uo pipefail

COMPOSE_DIR=/home/albor/docker/compose
GLUETUN_DEPS=(qbittorrent nzbget prowlarr radarr sonarr readarr listenarr agregarr cleanuparr huntarr byparr)
MAX_RETRIES=5
RETRY_DELAY=30

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

check_all_running() {
    local expected running not_running
    expected=$(docker compose config --services 2>&1 | grep -cv "^time=\|^WARN" || true)
    if [ "$expected" -eq 0 ]; then
        log "ERROR: docker compose config returned no services"
        echo "999"
        return
    fi
    running=$(docker compose ps --status running --format '{{.Name}}' 2>/dev/null | wc -l || true)
    not_running=$((expected - running))
    if [ "$not_running" -lt 0 ]; then not_running=0; fi
    log "Services: $running/$expected running"
    echo "$not_running"
}

start_created() {
    local created
    created=$(docker compose ps -a --status created --format '{{.Name}}' 2>/dev/null)
    if [ -n "$created" ]; then
        log "Starting Created containers: $created"
        echo "$created" | xargs -r docker start 2>&1 || true
    fi
}

cd "$COMPOSE_DIR"

# Phase 1: Start everything normally (handles non-VPN services)
log "Phase 1: Starting all services..."
docker compose up -d --remove-orphans 2>&1 || true

sleep 10

NOT_RUNNING=$(check_all_running)
if [ "$NOT_RUNNING" -eq 0 ]; then
    log "All services running after Phase 1."
    exit 0
fi
log "$NOT_RUNNING service(s) not running after Phase 1."

# Phase 2: Force-recreate Gluetun and dependents to fix stale network namespaces
log "Phase 2: Force-recreating Gluetun stack..."
docker compose up -d --force-recreate gluetun "${GLUETUN_DEPS[@]}" 2>&1 || true

sleep 10

NOT_RUNNING=$(check_all_running)
if [ "$NOT_RUNNING" -eq 0 ]; then
    log "All services running after Phase 2."
    exit 0
fi
log "$NOT_RUNNING service(s) not running after Phase 2."

# Phase 3: Retry loop for any stragglers (start Created containers directly)
for attempt in $(seq 1 "$MAX_RETRIES"); do
    log "Phase 3, attempt $attempt/$MAX_RETRIES..."

    start_created
    docker compose up -d 2>&1 || true

    sleep 10

    NOT_RUNNING=$(check_all_running)
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
log "WARNING: Some services still not running after all phases:"
docker compose ps -a --format "table {{.Name}}\t{{.Status}}" 2>&1 | grep -v "running" || true
exit 1
