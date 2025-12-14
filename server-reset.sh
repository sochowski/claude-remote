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

# Function to check if mount point exists
check_mount_point() {
    if [ ! -d "$MOUNT_POINT" ]; then
        echo "Mount point $MOUNT_POINT does not exist"
        return 1
    fi
    return 0
}

# Function to force unmount
force_unmount() {
    local mount_point="$1"
    echo "Attempting to unmount $mount_point..."

    # Try fusermount first (cleanest for FUSE)
    if command -v fusermount &> /dev/null; then
        echo "  Trying fusermount -uz..."
        if fusermount -uz "$mount_point" 2>/dev/null; then
            echo "  ✓ Successfully unmounted with fusermount"
            return 0
        fi
    fi

    # Try regular umount with force
    echo "  Trying umount -f..."
    if umount -f "$mount_point" 2>/dev/null; then
        echo "  ✓ Successfully unmounted with umount -f"
        return 0
    fi

    # Try lazy unmount as last resort
    echo "  Trying umount -l (lazy)..."
    if umount -l "$mount_point" 2>/dev/null; then
        echo "  ✓ Successfully unmounted with umount -l (lazy)"
        return 0
    fi

    echo "  ✗ Failed to unmount"
    return 1
}

# Function to kill any hanging sshfs processes for THIS mount point only
kill_sshfs_processes() {
    echo ""
    echo "Checking for hanging sshfs processes for $MOUNT_POINT..."

    # Find sshfs processes specifically mounting to our mount point
    # This grep pattern looks for sshfs with our exact mount point path
    SSHFS_PIDS=$(ps aux | grep "[s]shfs.*${MOUNT_POINT}\$" | awk '{print $2}')

    if [ -z "$SSHFS_PIDS" ]; then
        echo "  No sshfs processes found for $MOUNT_POINT"
        return 0
    fi

    # Show what we found
    echo "  Found sshfs processes for this mount point:"
    ps aux | grep "[s]shfs.*${MOUNT_POINT}\$" | while read line; do
        echo "    $line"
    done

    echo ""
    echo "  Process IDs to kill: $SSHFS_PIDS"
    echo "  Killing processes..."

    for pid in $SSHFS_PIDS; do
        # First try SIGTERM (graceful)
        if kill "$pid" 2>/dev/null; then
            echo "  ✓ Sent SIGTERM to process $pid"
            sleep 1
            # Check if it's still running
            if ps -p "$pid" > /dev/null 2>&1; then
                # Still running, use SIGKILL
                if kill -9 "$pid" 2>/dev/null; then
                    echo "  ✓ Sent SIGKILL to process $pid"
                fi
            fi
        else
            echo "  ✗ Failed to kill process $pid (may already be dead)"
        fi
    done

    sleep 1
}

# Main reset logic
echo "Checking mount point..."
if ! check_mount_point; then
    echo "Nothing to reset"
    exit 0
fi

# Check if currently mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "Mount point is currently mounted"
    force_unmount "$MOUNT_POINT"

    # Verify unmount was successful
    sleep 1
    if mountpoint -q "$MOUNT_POINT"; then
        echo ""
        echo "WARNING: Mount point is still mounted after unmount attempts"
        kill_sshfs_processes
        force_unmount "$MOUNT_POINT"
    fi
else
    echo "Mount point is not currently mounted"
fi

# Final check and kill any lingering processes
kill_sshfs_processes

# Final verification
echo ""
if mountpoint -q "$MOUNT_POINT"; then
    echo "FAILED: Mount point is still mounted"
    echo ""
    echo "You may need to manually intervene:"
    echo "  1. Check for processes: lsof +D $MOUNT_POINT"
    echo "  2. Kill processes: pkill -9 -f sshfs"
    echo "  3. Force unmount: sudo umount -f $MOUNT_POINT"
    exit 1
else
    echo "SUCCESS: Reset complete"
    echo "  Mount point: $MOUNT_POINT"
    echo "  Status: Clean"
    exit 0
fi
