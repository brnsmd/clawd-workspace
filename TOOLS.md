# TOOLS.md - Local Notes

Skills define *how* tools work. This file is for *your* specifics — the stuff that's unique to your setup.

## Mirror Nodes (Handoff)

Two identical Broodbrothers, same Telegram bot, manual switch:

| Node | Location | Tailscale IP | Status |
|------|----------|--------------|--------|
| home | Home Server | 100.118.246.104 | ✅ Active |
| work | Work PC | TBD | ⏸️ Setup pending |

**Handoff commands:**
- `/handoff work` — Stop home, start work
- `/handoff home` — Stop work, start home

**Config:** `infra/nodes.yaml`

**Setup work PC:**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
iwr -Uri "https://raw.githubusercontent.com/brnsmd/clawd-workspace/main/scripts/bootstrap-mirror.ps1" -OutFile "$env:TEMP\bootstrap.ps1"
& "$env:TEMP\bootstrap.ps1"
```

## Brood Toolbox

On Fedora Atomic, I have a dedicated toolbox container with extra tools:

```bash
# Enter toolbox
toolbox enter brood

# Or run single command
toolbox run -c brood <command>
```

**Installed tools:**
- `bat` - syntax-highlighted cat
- `fzf` - fuzzy finder
- `htop` - process viewer
- `trash-cli` - safe deletion (trash-put, trash-list, trash-restore)
- `tree` - directory visualization
- `ffmpeg` - video/audio processing
- `ImageMagick` - image processing (convert, identify, mogrify)
- `pandoc` - document conversion
- `jq` - JSON processing
- `ripgrep` (rg) - fast grep
- `fd` - fast find
- `yt-dlp` - video/audio downloads

**Python packages (pip --user):**
- `gkeepapi` - Google Keep API (needs auth setup)

---

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
