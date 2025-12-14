# Claude Remote

Run Claude Code on a remote server while editing local files.

## How It Works

1. Client connects to server via SSH with reverse tunnel
2. Server mounts client filesystem via SSHFS through tunnel
3. Server runs Claude Code on mounted files
4. All edits happen on your local files

## Quick Start (Recommended)

**Server:**
```bash
./setup-server.sh
```

**Client:**
```bash
# Install cr CLI (add to PATH)
sudo ln -s "$(pwd)/cr" /usr/local/bin/cr
# OR add to your shell profile:
# export PATH="$PATH:/path/to/claude-remote"

# First time: configure your connection
cr --config

# Connect to remote
cr ~/myproject

# Reset if needed
cr --reset
```

## Manual Setup (Alternative)

**Server:**
```bash
./setup-server.sh
```

**Client:**
```bash
chmod +x client-connect.sh
export SERVER_HOST=your-server.com
./client-connect.sh ~/myproject
```

## Requirements

- **Server**: Claude Code, sshfs
- **Client**: SSH server running
- **Both**: SSH key auth recommended

## Security

**Good:**
- All traffic encrypted via SSH
- API key stays on server only
- Reverse tunnel only binds to localhost

**Risks:**
- Server can access client files (use trusted servers only)
- Commands execute on server (not client)
- Password stored in plaintext in `~/.crconfig` if using password storage

**Recommended: Use SSH keys instead of passwords**
```bash
# Client -> Server
ssh-copy-id user@server.com

# For passwordless mount, use SSH agent forwarding:
eval $(ssh-agent) && ssh-add
```

**Password storage (if needed):**
The `cr` CLI can store your password for convenience, but this stores it in plaintext.
For better security:
1. Use SSH keys (recommended)
2. Use `ssh-agent` with key forwarding
3. Install `sshpass` if using password storage: `sudo apt install sshpass`

## CLI Usage

The `cr` command provides a simple interface:

```bash
cr [project_dir]          # Connect (default: current directory)
cr -r, --reset            # Reset/cleanup remote mount
cr -c, --config           # Edit configuration
cr -h, --help             # Show help
```

**First time setup:**
```bash
cr --config
```
You'll be prompted for:
- Remote server hostname/IP
- Usernames (remote and local)
- Optional password storage (or use SSH keys - recommended)

**Configuration file:** `~/.crconfig`

## Reset/Cleanup

If you encounter hanging mounts or stale connections:

**Using cr CLI:**
```bash
cr --reset
```

**Manual method:**
```bash
SERVER_HOST=your-server.com ./client-reset.sh
```

**Or directly on server:**
```bash
claude-remote-reset
```

This will forcibly unmount `~/claude-remote-mount` and clean up any related processes.

## Troubleshooting

**Mount fails**: Make sure SSH server is running on client
```bash
sudo systemctl start sshd  # Linux
sudo systemsetup -setremotelogin on  # macOS
```

**Hanging/stale mount**: Use the reset script (see above)

**claude not found**: Install Claude Code on server

**Port in use**: Wait for other session to finish or use different port
