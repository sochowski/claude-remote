#!/bin/bash
# Client-side reset script: Trigger reset on remote server
# This script runs on the client machine and calls the reset script on the server
#
# Usage: ./client-reset.sh
#
# Environment variables (or edit this script):
#   SERVER_HOST - Remote server hostname/IP (required)
#   SERVER_USER - Your username on the server (default: current user)

# Configuration - EDIT THESE or set as environment variables
SERVER_HOST="${SERVER_HOST:-}"
SERVER_USER="${SERVER_USER:-$(whoami)}"

# Validate configuration
if [ -z "$SERVER_HOST" ]; then
    echo "Error: SERVER_HOST not set"
    echo ""
    echo "Usage: SERVER_HOST=myserver.com $0"
    echo "   or: export SERVER_HOST=myserver.com"
    echo "       $0"
    echo ""
    echo "Examples:"
    echo "  SERVER_HOST=example.com $0"
    exit 1
fi

echo "Resetting remote claude-remote-mount on $SERVER_USER@$SERVER_HOST..."
echo ""

# SSH to server and run reset script
ssh -t "$SERVER_USER@$SERVER_HOST" "claude-remote-reset"

echo ""
echo "Reset command completed"
