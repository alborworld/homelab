#!/bin/bash
# Scheduled update for Gluetun and its network_mode dependents.
# Pulls new images and force-recreates the entire Gluetun stack together,
# preserving correct network namespace references.
#
# Why a dedicated script:
# Per-container updaters are not dependency-aware for network_mode:
# service:<name> — recreating Gluetun alone leaves dependents bound to a
# stale container ID. WUD therefore only notifies about new images; this
# script handles updates for the entire group atomically.
#
# Crontab entry:
#   45 6 * * * /home/albor/docker/compose/scripts/update-gluetun-stack.sh >> /home/albor/docker/logs/gluetun-update.log 2>&1

set -uo pipefail

COMPOSE_DIR=/home/albor/docker/compose
GLUETUN_DEPS=(qbittorrent nzbget prowlarr radarr sonarr listenarr agregarr cleanuparr huntarr byparr)

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cd "$COMPOSE_DIR"

log "Pulling Gluetun stack images..."
for svc in gluetun "${GLUETUN_DEPS[@]}"; do
    docker compose pull "$svc" 2>&1 || log "WARNING: Failed to pull $svc (continuing)"
done

log "Force-recreating Gluetun stack..."
if docker compose up -d --force-recreate gluetun "${GLUETUN_DEPS[@]}" 2>&1; then
    log "Done."
else
    log "ERROR: Failed to recreate Gluetun stack (exit $?)"
    exit 1
fi
