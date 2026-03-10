#!/bin/bash
# Scheduled update for Gluetun and its network_mode dependents.
# Runs after Watchtower to pull new images and force-recreate the entire
# Gluetun stack together, preserving correct network namespace references.
#
# Why not Watchtower:
# Watchtower is not dependency-aware for network_mode: service:<name>.
# All Gluetun stack containers have watchtower.enable=false to prevent
# Watchtower from recreating Gluetun independently (which breaks dependents).
# This script handles updates for the entire group atomically.
#
# Crontab entry (runs 15 min after Watchtower at 6:30 CET):
#   45 6 * * * /home/albor/docker/compose/scripts/update-gluetun-stack.sh >> /home/albor/docker/logs/gluetun-update.log 2>&1

set -uo pipefail

COMPOSE_DIR=/home/albor/docker/compose
GLUETUN_DEPS=(qbittorrent nzbget prowlarr radarr sonarr readarr listenarr agregarr cleanuparr huntarr byparr)

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
