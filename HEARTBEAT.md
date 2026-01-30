# HEARTBEAT.md

## Active Watch: CLUG Hunting

### Every Heartbeat (~15 min)
- [ ] Check CLUG: `tmux capture-pane -p -t clug:0.0 -S -50`
- [ ] Look for permission prompts → approve if stuck
- [ ] Check for errors or blocks
- [ ] Report significant progress to Grug

### Quick Status Commands
```bash
tmux capture-pane -p -t clug:0.0 -S -50  # CLUG screen
cd ~/Projects/Zav && bd list              # Beads status
boss-status                               # Services
```

### Alert Grug When:
- Task completed
- CLUG stuck >5 min
- Errors encountered
- Permission needed that I can't approve
