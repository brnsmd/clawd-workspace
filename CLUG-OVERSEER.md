# CLUG Overseer Protocol

Broodbrother monitors and coordinates with Claude Code (CLUG) on Zav development.

## Architecture

```
     Heorhii (Telegram/Slack)
            │
            ▼
    ┌───────────────┐
    │  Broodbrother │  ◄── overseer, communicator
    │   (always on) │
    └───────┬───────┘
            │ monitors beads + tmux
            ▼
    ┌───────────────┐
    │  Claude Code  │  ◄── coder, boar-hunter  
    │    (CLUG)     │
    └───────┬───────┘
            │
            ▼
    ~/Projects/Zav (.beads/)
```

## Monitoring Channels

### 1. Beads (Issue Tracker)
```bash
cd /var/home/htsapenko/Projects/Zav

# What's being worked on
bd list --status=in_progress

# What's ready (unblocked)
bd ready

# Recent activity
bd activity

# Specific issue status
bd show Zav-xxx
```

### 2. tmux (Real-time)
When CLUG runs in tmux:
```bash
# Check if session exists
tmux list-sessions

# Peek at CLUG's output (last 50 lines)
tmux capture-pane -p -t clug:0.0 -S -50

# Watch live (human)
tmux attach -t clug
```

## Overseer Actions

### Routine Checks (Heartbeat)
1. `bd list --status=in_progress` — What's CLUG working on?
2. `bd ready` — Anything stuck/waiting?
3. Check tmux if session exists
4. Notify Heorhii if: progress made, issue closed, blocker hit

### On Request from Heorhii
- "What's CLUG doing?" → Check beads + tmux, report
- "Tell CLUG to do X" → Create bead, optionally nudge via tmux
- "Is X done?" → `bd show Zav-xxx`, report status

### Proactive Coordination
- If CLUG closes a P1 → notify immediately
- If issue stuck >2h → flag it
- If EMR/external access needed → alert (CLUG can't reach hospital systems)

## Creating Work for CLUG

```bash
cd /var/home/htsapenko/Projects/Zav

# Create a task
bd create --title="Fix VLK date parsing" --type=task --priority=1

# Add context in description
bd update Zav-xxx --description="The date format from EMR is DD.MM.YYYY but we expect ISO"

# CLUG will see it in `bd ready`
```

## Communication Protocol

### To Heorhii (via Telegram/Slack)
- 🟢 "CLUG closed Zav-xxx: [title]"
- 🟡 "CLUG working on Zav-xxx: [title]" 
- 🔴 "CLUG blocked on Zav-xxx — needs [context/access/decision]"

### To CLUG (via tmux)
```bash
# Send a message
tmux send-keys -t clug:0.0 "# BROOD: Check Zav-abc, priority increased" Enter

# Or just create a high-priority bead — CLUG checks bd ready
```

## Starting CLUG in Monitored Mode

When launching CLUG for a session:
```bash
# Create tmux session
tmux new-session -d -s clug -c /var/home/htsapenko/Projects/Zav

# Launch Claude Code
tmux send-keys -t clug "claude" Enter

# Print monitor commands
echo "Monitor: tmux attach -t clug"
echo "Peek: tmux capture-pane -p -t clug:0.0 -S -50"
```

## Session Boundaries

- CLUG handles: code, tests, git commits, beads updates
- Brood handles: external comms, context from Slack/email, coordination, monitoring
- Both respect: `bd sync --from-main` at boundaries

---

*The spider watches. The hunter hunts. The tribe prospers.*
