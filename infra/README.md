# Infrastructure

This folder contains deployment configs for the Broodbrother gateway.

## Files

- `../scripts/bootstrap-gateway.sh` — One-shot server setup script
- `clawdbot.yaml.template` — Config template (copy and fill in secrets)

## Deployment Options

### Option A: VPS (Hetzner, DigitalOcean, etc.)
See `../CLOUD-GATEWAY-PLAN.md`

### Option B: Always-On Local Machine
Same bootstrap script works. Just ensure:
- Tailscale installed for remote access
- UPS for power protection
- Auto-login + systemd service

## Quick Deploy

```bash
# On fresh server as root:
curl -fsSL https://raw.githubusercontent.com/brnsmd/clawd-workspace/main/scripts/bootstrap-gateway.sh | bash

# Or clone and run:
git clone git@github.com:brnsmd/clawd-workspace.git ~/clawd
bash ~/clawd/scripts/bootstrap-gateway.sh
```

## Environment Variables

Set these before starting (in `/etc/environment` or systemd override):

```bash
ANTHROPIC_API_KEY=sk-ant-...
# Add other channel tokens as needed
```
