# Claude Remote

Run Claude Code on a remote server while editing local files.

## How It Works

1. Client connects to server via SSH with reverse tunnel
2. Server mounts client filesystem via SSHFS through tunnel
3. Server runs Claude Code on mounted files
4. All edits happen on your local files

## Setup

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
- Use SSH keys, not passwords

**Setup SSH keys:**
```bash
# Client -> Server
ssh-copy-id user@server.com

# For passwordless mount, use SSH agent forwarding:
eval $(ssh-agent) && ssh-add
```

## Troubleshooting

**Mount fails**: Make sure SSH server is running on client
```bash
sudo systemctl start sshd  # Linux
sudo systemsetup -setremotelogin on  # macOS
```

**claude not found**: Install Claude Code on server

**Port in use**: Wait for other session to finish or use different port
