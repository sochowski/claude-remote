#!/bin/bash
# cr - Claude Remote CLI wrapper
# Simple interface for claude-remote with credential storage
#
# Usage:
#   cr [project_dir]          Connect to remote server
#   cr -r, --reset            Reset/cleanup remote mount
#   cr -c, --config           Edit configuration
#   cr -h, --help             Show help

set -e

CONFIG_FILE="$HOME/.crconfig"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Show help
show_help() {
    cat << EOF
cr - Claude Remote CLI

Usage:
  cr [project_dir]          Connect to remote server (default: current directory)
  cr -r, --reset            Reset/cleanup remote mount
  cr -c, --config           Edit configuration
  cr -h, --help             Show this help

Configuration:
  Config file: ~/.crconfig

  On first run, you'll be prompted to set up your connection details.
  To change settings later, use: cr --config

Examples:
  cr                        # Connect with current directory
  cr ~/myproject            # Connect with specific directory
  cr -r                     # Reset stale mount
EOF
}

# Create default config
create_config() {
    echo -e "${YELLOW}First time setup - let's configure your remote server${NC}"
    echo ""

    read -p "Remote server hostname or IP: " server_host
    read -p "Remote username (default: $(whoami)): " server_user
    server_user=${server_user:-$(whoami)}

    read -p "Local username (default: $(whoami)): " client_user
    client_user=${client_user:-$(whoami)}

    echo ""
    echo -e "${YELLOW}Password storage (optional):${NC}"
    echo "You can store your SSH password to avoid typing it each time."
    echo -e "${RED}WARNING: Password will be stored in plaintext in ~/.crconfig${NC}"
    echo "Better alternatives: Use SSH keys (ssh-copy-id) or ssh-agent"
    echo ""
    read -p "Store password? (y/N): " -n 1 -r
    echo

    password=""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -s -p "SSH password: " password
        echo
    fi

    # Write config
    cat > "$CONFIG_FILE" << EOF
# Claude Remote configuration
# Edit with: cr --config

SERVER_HOST="$server_host"
SERVER_USER="$server_user"
CLIENT_USER="$client_user"
PASSWORD="$password"
EOF

    chmod 600 "$CONFIG_FILE"
    echo ""
    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
    echo ""
}

# Edit config
edit_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}No config file found${NC}"
        create_config
        return
    fi

    ${EDITOR:-vim} "$CONFIG_FILE"
    echo -e "${GREEN}Configuration updated${NC}"
}

# Load config
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        create_config
    fi

    source "$CONFIG_FILE"

    # Validate required settings
    if [ -z "$SERVER_HOST" ]; then
        echo -e "${RED}Error: SERVER_HOST not set in $CONFIG_FILE${NC}"
        exit 1
    fi
}

# Connect to remote
connect() {
    local project_dir="${1:-$(pwd)}"

    load_config

    # Ensure project directory exists
    if [ ! -d "$project_dir" ]; then
        echo -e "${RED}Error: Directory '$project_dir' does not exist${NC}"
        exit 1
    fi

    # Get absolute path
    project_dir=$(cd "$project_dir" && pwd)

    echo -e "${GREEN}Connecting to $SERVER_USER@$SERVER_HOST...${NC}"
    echo "Client user: $CLIENT_USER"
    echo "Project directory: $project_dir"
    echo ""

    # Export for client-connect.sh
    export SERVER_HOST
    export SERVER_USER
    export CLIENT_USER

    # Use sshpass if password is configured
    if [ -n "$PASSWORD" ]; then
        if ! command -v sshpass &> /dev/null; then
            echo -e "${YELLOW}Warning: sshpass not installed, password will be ignored${NC}"
            echo "Install with: sudo apt install sshpass (or brew install sshpass on macOS)"
            echo ""
            exec "$SCRIPT_DIR/client-connect.sh" "$project_dir"
        else
            export SSHPASS="$PASSWORD"
            exec sshpass -e "$SCRIPT_DIR/client-connect.sh" "$project_dir"
        fi
    else
        exec "$SCRIPT_DIR/client-connect.sh" "$project_dir"
    fi
}

# Reset remote mount
reset() {
    load_config

    echo -e "${YELLOW}Resetting remote mount on $SERVER_USER@$SERVER_HOST...${NC}"
    echo ""

    # Export for client-reset.sh
    export SERVER_HOST
    export SERVER_USER

    # Use sshpass if password is configured
    if [ -n "$PASSWORD" ]; then
        if ! command -v sshpass &> /dev/null; then
            echo -e "${YELLOW}Warning: sshpass not installed, password will be ignored${NC}"
            exec "$SCRIPT_DIR/client-reset.sh"
        else
            export SSHPASS="$PASSWORD"
            exec sshpass -e "$SCRIPT_DIR/client-reset.sh"
        fi
    else
        exec "$SCRIPT_DIR/client-reset.sh"
    fi
}

# Main command dispatcher
case "${1:-}" in
    -h|--help)
        show_help
        ;;
    -r|--reset)
        reset
        ;;
    -c|--config)
        edit_config
        ;;
    *)
        connect "$1"
        ;;
esac
