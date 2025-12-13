#!/bin/bash
# Setup script for server-side installation
# Run this on your remote server to install the claude-remote-server script

echo "Claude Remote - Server Setup"
echo "=============================="
echo ""

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo "Warning: 'claude' command not found"
    echo "Please install Claude Code first: https://github.com/anthropics/claude-code"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if sshfs is installed
if ! command -v sshfs &> /dev/null; then
    echo "Error: 'sshfs' is not installed"
    echo ""
    echo "Install it with:"
    echo "  Ubuntu/Debian: sudo apt install sshfs"
    echo "  RHEL/CentOS:   sudo yum install fuse-sshfs"
    echo "  Arch:          sudo pacman -S sshfs"
    exit 1
fi

# Create ~/bin directory if it doesn't exist
mkdir -p "$HOME/bin"

# Copy server script to ~/bin
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/server-script.sh" "$HOME/bin/claude-remote-server"
chmod +x "$HOME/bin/claude-remote-server"

echo "Installed claude-remote-server to ~/bin/claude-remote-server"

# Check if ~/bin is in PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo ""
    echo "Warning: ~/bin is not in your PATH"
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "  export PATH=\"\$HOME/bin:\$PATH\""
    echo ""
fi

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Make sure SSH server is running on this machine"
echo "  2. Set up SSH key authentication for your user account"
echo "  3. On your client machine, run client-connect.sh"
