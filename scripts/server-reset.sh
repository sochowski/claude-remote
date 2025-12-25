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

# Function to clean up port 2222 (used for reverse tunnel)
cleanup_port_2222() {
    echo "Cleaning up port 2222 (reverse tunnel port)..."

    # Find processes listening on port 2222
    if command -v lsof &> /dev/null; then
        # Using lsof (more reliable)
        PORT_PIDS=$(lsof -ti:2222 2>/dev/null)
    else
        # Fallback to ss/netstat + ps
        PORT_PIDS=$(ss -tlnp 2>/dev/null | grep ':2222' | grep -oP 'pid=\K[0-9]+' || netstat -tlnp 2>/dev/null | grep ':2222' | awk '{print $7}' | grep -oP '^[0-9]+')
    fi

    if [ -n "$PORT_PIDS" ]; then
        echo "Found processes using port 2222: $PORT_PIDS"
        for pid in $PORT_PIDS; do
            kill "$pid" 2>/dev/null
        done
        sleep 1
    fi
}

# Main reset logic - just force everything clean
echo "Resetting $MOUNT_POINT..."
echo ""

# Clean up port 2222 first (kills SSH processes holding the reverse tunnel)
cleanup_port_2222

# Kill sshfs processes
kill_sshfs_processes

# Force unmount (will silently fail if nothing mounted - that's fine)
force_unmount "$MOUNT_POINT"

# Kill processes again in case any respawned
kill_sshfs_processes

echo ""
echo "Reset complete"
echo "  Mount point: $MOUNT_POINT"
echo "  Port 2222 cleaned up"
exit 0
