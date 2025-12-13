#!/bin/bash
# Client-side script: Connect to remote server with reverse tunnel for SSHFS
# This script runs on the client machine (your laptop)
#
# Usage: ./client-connect.sh [project_directory]
#
# Environment variables (or edit this script):
#   SERVER_HOST - Remote server hostname/IP (required)
#   SERVER_USER - Your username on the server (default: current user)
#   CLIENT_USER - Your username on this client machine (default: current user)

# Configuration - EDIT THESE or set as environment variables
SERVER_HOST="${SERVER_HOST:-}"
SERVER_USER="${SERVER_USER:-$(whoami)}"
CLIENT_USER="${CLIENT_USER:-$(whoami)}"
PROJECT_DIR="${1:-$(pwd)}"

# Validate configuration
if [ -z "$SERVER_HOST" ]; then
    echo "Error: SERVER_HOST not set"
    echo ""
    echo "Usage: SERVER_HOST=myserver.com $0 [project_directory]"
    echo "   or: export SERVER_HOST=myserver.com"
    echo "       $0 [project_directory]"
    echo ""
    echo "Examples:"
    echo "  SERVER_HOST=example.com $0"
    echo "  SERVER_HOST=example.com $0 ~/myproject"
    exit 1
fi

# Ensure project directory exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Directory '$PROJECT_DIR' does not exist"
    exit 1
fi

# Get absolute path
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

echo "Connecting to $SERVER_USER@$SERVER_HOST..."
echo "Client user: $CLIENT_USER"
echo "Project directory: $PROJECT_DIR"
echo ""

# SSH to server with reverse tunnel and run remote script
# -R 2222:localhost:22 creates reverse tunnel (server port 2222 -> client port 22)
# -t allocates a TTY for interactive session
ssh -t -R 2222:localhost:22 "$SERVER_USER@$SERVER_HOST" \
    "claude-remote-server '$CLIENT_USER' '$PROJECT_DIR'"
