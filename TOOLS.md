# TOOLS.md - Local Notes

Skills define *how* tools work. This file is for *your* specifics — the stuff that's unique to your setup.

## Zav Project

### bd (beads) - Issue Tracker
```bash
cd /var/home/htsapenko/Projects/Zav
bd list          # All issues
bd ready         # Unblocked work
bd show Zav-xxx  # Issue details
bd update Zav-xxx --status in_progress
bd close Zav-xxx --reason "Done because..."
bd create "Title" -p 1 -d "Description"
```

### Commands
- `boss` — Start Boss TUI (auto-starts services)
- `boss-relay` — Start with Tailscale for EMR access
- `boss-status` — Check all services

### Key Directories
- `/var/home/htsapenko/Projects/Zav/` — Main project
- `/var/home/htsapenko/Projects/Zav/boss-tui/` — Rust TUI + embedded server
- `/var/home/htsapenko/Projects/Zav/cyberintern-tui/` — Doctor TUI
- `/var/home/htsapenko/Projects/Zav/nurse-tui/` — Nurse TUI
- `/var/home/htsapenko/Projects/Zav/.beads/` — Issue tracking

### Secrets
- `~/.config/zav-secrets.env` — API keys, tokens (Airtable, ClickUp, Slack, etc.)

---

## Communication Channels

### Telegram
- Bot: @BroodBrotherBot
- Heorhii's ID: 227230975

### Slack
- Workspace: Zav Hospital
- Heorhii's user ID: U0AABU2LRS7

### Email
- tsapenko.heorhii@gmail.com (gog configured)
