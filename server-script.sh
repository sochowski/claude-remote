#!/bin/bash
# Server-side script: Mount client filesystem via reverse tunnel and run Claude Code
# This script should be installed on the server as ~/bin/claude-remote-server (or in PATH)
#
# Usage: claude-remote-server <client_user> <project_directory>
# This is called automatically by the client script, you don't run it directly

CLIENT_USER="$1"
PROJECT_DIR="$2"
MOUNT_POINT="$HOME/claude-remote-mount"

if [ -z "$CLIENT_USER" ] || [ -z "$PROJECT_DIR" ]; then
    echo "Error: Missing arguments"
    echo "Usage: claude-remote-server <client_user> <project_directory>"
    exit 1
fi

echo "Setting up remote Claude Code session..."
echo "Client user: $CLIENT_USER"
echo "Project directory: $PROJECT_DIR"
echo ""

# Function to check if mount is active (without hanging)
is_mounted() {
    local mount_point="$1"
    # Check /proc/mounts instead of using mountpoint command
    # This won't hang even if the mount is stale
    grep -qs " ${mount_point} " /proc/mounts
}

# Function to check if mount is healthy
is_mount_healthy() {
    local mount_point="$1"
    # Try to stat the mount point with a timeout
    # If this hangs or fails, the mount is stale
    timeout 2 stat "$mount_point" > /dev/null 2>&1
    return $?
}

# Function to force unmount stale mounts
force_unmount() {
    local mount_point="$1"
    echo "Cleaning up stale mount..."
    # Try fusermount first (for FUSE filesystems), then fall back to umount -f
    fusermount -uz "$mount_point" 2>/dev/null || umount -f "$mount_point" 2>/dev/null
    sleep 1
}

# Create mount point if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Check if already mounted and if so, verify it's healthy
ALREADY_MOUNTED=false
if is_mounted "$MOUNT_POINT"; then
    echo "Checking existing mount at $MOUNT_POINT..."
    if is_mount_healthy "$MOUNT_POINT"; then
        echo "Client filesystem already mounted and healthy"
        ALREADY_MOUNTED=true
    else
        echo "Stale mount detected, cleaning up..."
        force_unmount "$MOUNT_POINT"
        ALREADY_MOUNTED=false
    fi
fi

# Mount if not already mounted (or if we just cleaned up a stale mount)
if [ "$ALREADY_MOUNTED" = false ]; then
    echo "Mounting client filesystem via reverse tunnel..."
    # Mount client filesystem through the reverse tunnel (localhost:2222 -> client:22)
    # -o StrictHostKeyChecking=no: Don't prompt for host key (it's localhost via tunnel)
    # -o UserKnownHostsFile=/dev/null: Don't save localhost:2222 to known_hosts
    sshfs -p 2222 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$CLIENT_USER@localhost:/" "$MOUNT_POINT"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to mount client filesystem"
        echo ""
        echo "Make sure:"
        echo "  1. SSH server is running on your client machine"
        echo "  2. You can SSH to your client as '$CLIENT_USER'"
        echo "  3. Server can authenticate (use ssh-copy-id or ssh-agent forwarding)"
        exit 1
    fi
    echo "Client filesystem mounted successfully"
fi

# Set up cleanup to unmount if we mounted it
cleanup() {
    if [ "$ALREADY_MOUNTED" = false ]; then
        echo ""
        echo "Unmounting client filesystem..."
        fusermount -u "$MOUNT_POINT" 2>/dev/null || umount "$MOUNT_POINT" 2>/dev/null
    fi
}
trap cleanup EXIT

# Change to the project directory on the mounted filesystem
FULL_PATH="$MOUNT_POINT$PROJECT_DIR"
if [ ! -d "$FULL_PATH" ]; then
    echo "Error: Project directory '$PROJECT_DIR' does not exist on client"
    exit 1
fi

cd "$FULL_PATH" || exit 1

echo ""
echo "Starting Claude Code on client directory: $PROJECT_DIR"
echo "---"
echo ""

# Run Claude Code with context about the remote setup
exec claude --append-system-prompt "You are running on a remote server with files mounted from the client machine via SSHFS over a reverse SSH tunnel. All commands you execute run on the server. The files you're editing are on the client's filesystem through the SSHFS mount at $MOUNT_POINT. To run commands directly on the client machine, you would need to SSH to it (client accessible via localhost:2222 during this session)."
