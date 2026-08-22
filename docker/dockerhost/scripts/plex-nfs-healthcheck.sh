#!/bin/bash
# Healthcheck for Plex and the /media NFS mount from diskstation.
#
# Why this exists:
# diskstation powers off nightly (midnight-6am), which drops the NFS mount that
# Plex serves its libraries from. When the NAS comes back the mount does not
# always recover on its own, and Plex keeps running with an empty library
# instead of failing visibly. This remounts /media and restarts Plex so the
# container re-reads the mount.
#
# Crontab entry:
#   */5 * * * * /home/albor/docker/compose/scripts/plex-nfs-healthcheck.sh >> /home/albor/docker/logs/nfs-healthcheck.log 2>&1

# Define variables
MOUNT_POINT="/media/movies"
CONTAINER_NAME="Plex"

# Check if the mount point exists
if [ ! -d "$MOUNT_POINT" ]; then
    echo "$(date): $MOUNT_POINT not found. Trying to remount..."
    /usr/bin/mount /media

    # Give it a few seconds to settle
    sleep 5

    # Check again
    if [ -d "$MOUNT_POINT" ]; then
        echo "$(date): Remount successful. Restarting Plex container..."
        /usr/bin/docker restart "$CONTAINER_NAME"
    else
        echo "$(date): Remount failed. Check NAS availability!"
    fi
else
    echo "$(date): $MOUNT_POINT exists. All good."
fi
