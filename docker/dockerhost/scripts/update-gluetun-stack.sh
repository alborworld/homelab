#!/bin/bash
# Scheduled update for Gluetun and its network_mode dependents.
# Runs after Watchtower (which excludes this group) to pull new images
# and recreate containers with correct network namespace references.
#
# Why not Watchtower:
# Watchtower is not dependency-aware for network_mode: service:<name>.
# When it recreates Gluetun, dependent containers keep a stale reference
# to the old container ID. traefik-kop can't resolve their IPs, breaking
# Traefik routing. Using `docker compose up -d --always-recreate-deps`
# ensures dependents are recreated when Gluetun changes.
#
# Crontab entry (runs 15 min after Watchtower at 6:30):
#   45 6 * * * /home/albor/docker/compose/scripts/update-gluetun-stack.sh >> /home/albor/docker/logs/gluetun-update.log 2>&1

set -uo pipefail

COMPOSE_DIR=/home/albor/docker/compose

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cd "$COMPOSE_DIR"

log "Pulling Gluetun stack images..."
docker compose pull gluetun qbittorrent nzbget prowlarr radarr sonarr readarr agregarr cleanuparr huntarr byparr 2>&1

log "Recreating Gluetun and dependents if images changed..."
docker compose up -d --always-recreate-deps gluetun 2>&1

log "Done."
