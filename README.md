# Claude Remote

Run Claude Code on a remote server while editing local files. My laptop doesn't meet the hardware requirements for Claude Code.

## Installation

**Server:**
```bash
./scripts/setup-server.sh
```

**Client:**
```bash
# Add to PATH
sudo ln -s "$(pwd)/cr" /usr/local/bin/cr

# First run: configure connection
cr --config
```

## Configuration

Config file: `~/.crconfig`

```bash
SERVER_HOST="your-server.com"
SERVER_USER="username"
CLIENT_USER="username"
PASSWORD=""  # Optional, use SSH keys instead
```

Edit with: `cr --config`

## Usage

```bash
cr [project_dir]          # Connect (default: current directory)
cr -s, --ssh              # SSH only (no Claude session, no reverse mount)
cr -n, --no-mount [dir]   # Skip reverse mount (shell on server)
cr -r, --reset            # Reset/cleanup remote mount
cr -c, --config           # Edit configuration
cr -h, --help             # Show help
```

## Requirements

- **Server**: Claude Code, sshfs
- **Client**: SSH server running
- **Recommended**: SSH key authentication
