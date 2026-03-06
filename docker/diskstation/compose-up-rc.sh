#!/bin/bash
# Synology boot script — install to /usr/local/etc/rc.d/compose-up.sh
# Ensures all Docker Compose services start after reboot.
#
# Install:
#   sudo cp compose-up-rc.sh /usr/local/etc/rc.d/compose-up.sh
#   sudo chmod 755 /usr/local/etc/rc.d/compose-up.sh

LOGFILE="/var/log/compose-up.log"
SCRIPT="/volume1/docker/compose/scripts/compose-up.sh"

case "$1" in
    start)
        # Wait for Docker daemon to be ready
        for i in $(seq 1 30); do
            /usr/local/bin/docker info >/dev/null 2>&1 && break
            sleep 2
        done
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting compose services..." >> "$LOGFILE"
        "$SCRIPT" >> "$LOGFILE" 2>&1 &
        ;;
    stop)
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] System shutting down" >> "$LOGFILE"
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
