# Cloud Gateway + Local Node Setup Plan

**Goal:** Run Clawdbot Gateway 24/7 on a VPS, with laptop as optional node for local file access.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└─────────────────────────────────────────────────────────────┘
          │                              │
          ▼                              ▼
┌─────────────────┐            ┌─────────────────┐
│   Telegram API  │            │    Slack API    │
│   Signal, etc.  │            │    Email, etc.  │
└────────┬────────┘            └────────┬────────┘
         │                              │
         └──────────────┬───────────────┘
                        ▼
         ┌──────────────────────────┐
         │      VPS (Hetzner)       │
         │  ┌────────────────────┐  │
         │  │  Clawdbot Gateway  │  │
         │  │  - Always online   │  │
         │  │  - Handles msgs    │  │
         │  │  - Runs cron jobs  │  │
         │  └────────────────────┘  │
         │          │               │
         │     Tailscale mesh       │
         └──────────┬───────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌───────────────┐       ┌───────────────┐
│    Laptop     │       │  (Future?)    │
│  Local Node   │       │  Phone Node   │
│  - Projects   │       │  - Camera     │
│  - Zav files  │       │  - Location   │
│  - When on    │       │               │
└───────────────┘       └───────────────┘
```

---

## Phase 1: VPS Setup (30 min)

### 1.1 Create Hetzner Account
- [ ] Go to https://www.hetzner.com/cloud
- [ ] Create account (needs email, payment method)
- [ ] Choose datacenter: **Falkenstein (fsn1)** or **Helsinki (hel1)** — closest to Kyiv

### 1.2 Create Server
- [ ] Type: **CX22** (2 vCPU, 4GB RAM, 40GB SSD) — €4.35/month
  - Or **CX11** (1 vCPU, 2GB RAM) — €3.29/month if budget tight
- [ ] OS: **Fedora 42** (match your laptop) or **Ubuntu 24.04 LTS**
- [ ] Enable: **IPv4** (needed for some APIs)
- [ ] SSH Key: Add your public key (`cat ~/.ssh/id_ed25519.pub`)
- [ ] Name: `clawd-gateway` or `brood-nest`

### 1.3 Initial Server Hardening
```bash
# SSH into server
ssh root@<server-ip>

# Create non-root user
useradd -m -G wheel -s /bin/bash htsapenko
passwd htsapenko

# Enable sudo
echo "htsapenko ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/htsapenko

# Copy SSH key to new user
mkdir -p /home/htsapenko/.ssh
cp ~/.ssh/authorized_keys /home/htsapenko/.ssh/
chown -R htsapenko:htsapenko /home/htsapenko/.ssh

# Disable root SSH (edit /etc/ssh/sshd_config)
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Firewall (if using firewalld)
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
```

---

## Phase 2: Tailscale Setup (15 min)

### 2.1 Install Tailscale on VPS
```bash
# On VPS
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh

# Note the Tailscale IP (100.x.x.x)
tailscale ip -4
```

### 2.2 Verify Laptop Connection
```bash
# On laptop (should already have Tailscale)
tailscale status

# Should see both devices in the mesh
```

### 2.3 Test Connectivity
```bash
# From laptop, SSH to VPS via Tailscale
ssh htsapenko@<vps-tailscale-ip>
```

---

## Phase 3: Clawdbot on VPS (20 min)

### 3.1 Install Dependencies
```bash
# On VPS
sudo dnf install -y nodejs npm git

# Or for Ubuntu:
# curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
# sudo apt install -y nodejs git
```

### 3.2 Install Clawdbot
```bash
# On VPS as htsapenko
npm install -g clawdbot

# Create workspace
mkdir -p ~/clawd
cd ~/clawd

# Initialize (this creates config)
clawdbot init
```

### 3.3 Copy Config from Laptop
We'll need to migrate your current config. On laptop:
```bash
# Export current config
clawdbot gateway config.get > ~/clawd-config-backup.yaml
```

Then we'll adapt it for VPS (channels stay same, workspace changes).

### 3.4 Set Up Systemd Service
```bash
# On VPS
sudo tee /etc/systemd/system/clawdbot.service << 'EOF'
[Unit]
Description=Clawdbot Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=htsapenko
WorkingDirectory=/home/htsapenko/clawd
ExecStart=/home/htsapenko/.npm-global/bin/clawdbot gateway start --foreground
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable clawdbot
sudo systemctl start clawdbot
```

---

## Phase 4: Local Node Setup (15 min)

### 4.1 Configure Laptop as Node
The laptop will connect to the VPS gateway as a "node", allowing remote file access and command execution when online.

```bash
# On laptop
clawdbot node pair --gateway https://<vps-tailscale-ip>:3000
```

### 4.2 Auto-reconnect Service (Optional)
```bash
# Systemd user service for auto-reconnect
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/clawdbot-node.service << 'EOF'
[Unit]
Description=Clawdbot Node Connection
After=network-online.target tailscaled.service

[Service]
Type=simple
ExecStart=/home/htsapenko/.npm-global/bin/clawdbot node connect
Restart=always
RestartSec=30

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable clawdbot-node
systemctl --user start clawdbot-node
```

---

## Phase 5: Migration Checklist

### 5.1 Secrets & API Keys
- [ ] Anthropic API key → VPS environment
- [ ] Telegram bot token → VPS config
- [ ] Slack tokens → VPS config  
- [ ] Any other channel credentials

### 5.2 Workspace Files
- [ ] Copy SOUL.md, USER.md, AGENTS.md, etc. to VPS
- [ ] Or: sync via git (recommended)

### 5.3 Memory Files
- [ ] Decide: memory on VPS or laptop?
- [ ] Option A: Memory on VPS (always accessible)
- [ ] Option B: Memory on laptop (more private, but gaps when offline)
- [ ] Recommendation: Memory on VPS, sensitive project files stay on laptop

### 5.4 Channel Cutover
- [ ] Stop gateway on laptop: `clawdbot gateway stop`
- [ ] Start gateway on VPS: `sudo systemctl start clawdbot`
- [ ] Test Telegram/Slack still work
- [ ] Set up laptop as node

---

## Phase 6: Verification

### 6.1 Test Always-On
- [ ] Close laptop lid → messages still arrive on VPS
- [ ] VPS responds to Telegram
- [ ] Cron jobs fire correctly

### 6.2 Test Node Access
- [ ] Open laptop → node reconnects
- [ ] From Telegram, ask me to read a file from ~/Projects/Zav
- [ ] Verify I can access it through the node

### 6.3 Test Failover
- [ ] Disconnect laptop → I should note node offline but keep working
- [ ] Reconnect → node comes back automatically

---

## Cost Summary

| Item | Cost |
|------|------|
| Hetzner CX22 | €4.35/month |
| Tailscale | Free (personal use) |
| Domain (optional) | ~€10/year |
| **Total** | **~€5/month** |

---

## Security Notes

1. **All traffic over Tailscale** — encrypted, no public ports except SSH
2. **VPS has no patient data** — just gateway + my workspace files
3. **Sensitive files stay on laptop** — accessed only via node when online
4. **API keys in environment variables** — not in config files
5. **Regular VPS snapshots** — Hetzner offers cheap backups

---

## Next Steps

1. Create Hetzner account
2. Spin up VPS
3. I'll guide you through each phase

Ready when you are! 🕷️
