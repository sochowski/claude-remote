#!/bin/bash
# Server-side reset script: Force unmount and clean up claude-remote-mount
# This script should be installed on the server as ~/bin/claude-remote-reset (or in PATH)
#
# Usage: claude-remote-reset
# Can be called directly on the server or via client-reset.sh from the client

MOUNT_POINT="$HOME/claude-remote-mount"

echo "Claude Remote - Reset Script"
echo "============================="
echo ""

# Function to force unmount
force_unmount() {
    local mount_point="$1"
    echo "Forcing unmount of $mount_point..."

    # Try fusermount first (cleanest for FUSE)
    if command -v fusermount &> /dev/null; then
        fusermount -uz "$mount_point" 2>/dev/null
    fi

    # Try regular umount with force
    umount -f "$mount_point" 2>/dev/null

    # Try lazy unmount as last resort
    umount -l "$mount_point" 2>/dev/null
}

# Function to kill any hanging sshfs processes for THIS mount point only
kill_sshfs_processes() {
    echo "Killing any sshfs processes for $MOUNT_POINT..."

    # Find sshfs processes specifically mounting to our mount point
    SSHFS_PIDS=$(ps aux | grep "[s]shfs.*${MOUNT_POINT}\$" | awk '{print $2}')

    if [ -n "$SSHFS_PIDS" ]; then
        for pid in $SSHFS_PIDS; do
            kill -9 "$pid" 2>/dev/null
        done
        sleep 1
    fi
}

# Main reset logic - just force everything clean
echo "Resetting $MOUNT_POINT..."
echo ""

# Kill processes first
kill_sshfs_processes

# Force unmount (will silently fail if nothing mounted - that's fine)
force_unmount "$MOUNT_POINT"

# Kill processes again in case any respawned
kill_sshfs_processes

echo ""
echo "Reset complete"
echo "  Mount point: $MOUNT_POINT"
exit 0
