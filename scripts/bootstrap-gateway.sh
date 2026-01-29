#!/usr/bin/env bash
#
# Bootstrap script for Clawdbot Gateway on a fresh server
# Run as: curl -fsSL <raw-url> | bash
# Or: bash bootstrap-gateway.sh
#
set -euo pipefail

CLAWD_USER="${CLAWD_USER:-htsapenko}"
CLAWD_REPO="${CLAWD_REPO:-git@github.com:brnsmd/clawd-workspace.git}"
CLAWD_DIR="/home/${CLAWD_USER}/clawd"

echo "🕷️  Broodbrother Gateway Bootstrap"
echo "=================================="
echo ""

# Detect package manager
if command -v dnf &>/dev/null; then
    PKG="dnf"
    INSTALL="sudo dnf install -y"
elif command -v apt &>/dev/null; then
    PKG="apt"
    INSTALL="sudo apt update && sudo apt install -y"
else
    echo "❌ Unsupported OS (need dnf or apt)"
    exit 1
fi

echo "📦 Package manager: $PKG"
echo ""

# ─────────────────────────────────────────────────────────────
# 1. System packages
# ─────────────────────────────────────────────────────────────
echo "📦 Installing system packages..."
if [ "$PKG" = "dnf" ]; then
    sudo dnf install -y git curl nodejs npm
else
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y git curl nodejs
fi

# ─────────────────────────────────────────────────────────────
# 2. Tailscale
# ─────────────────────────────────────────────────────────────
echo ""
echo "🔗 Installing Tailscale..."
if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
    echo ""
    echo "⚠️  Run 'sudo tailscale up --ssh' after bootstrap to authenticate"
else
    echo "   Already installed"
fi

# ─────────────────────────────────────────────────────────────
# 3. Create user if needed (skip if running as that user)
# ─────────────────────────────────────────────────────────────
if [ "$(whoami)" = "root" ] && ! id "$CLAWD_USER" &>/dev/null; then
    echo ""
    echo "👤 Creating user: $CLAWD_USER"
    useradd -m -G wheel -s /bin/bash "$CLAWD_USER"
    echo "$CLAWD_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$CLAWD_USER
    
    # Copy SSH keys from root
    if [ -f /root/.ssh/authorized_keys ]; then
        mkdir -p /home/$CLAWD_USER/.ssh
        cp /root/.ssh/authorized_keys /home/$CLAWD_USER/.ssh/
        chown -R $CLAWD_USER:$CLAWD_USER /home/$CLAWD_USER/.ssh
        chmod 700 /home/$CLAWD_USER/.ssh
        chmod 600 /home/$CLAWD_USER/.ssh/authorized_keys
    fi
fi

# ─────────────────────────────────────────────────────────────
# 4. Install Clawdbot
# ─────────────────────────────────────────────────────────────
echo ""
echo "🤖 Installing Clawdbot..."

# Set up npm global for user
NPM_GLOBAL="/home/${CLAWD_USER}/.npm-global"
if [ "$(whoami)" = "root" ]; then
    sudo -u "$CLAWD_USER" bash -c "
        mkdir -p $NPM_GLOBAL
        npm config set prefix $NPM_GLOBAL
        export PATH=$NPM_GLOBAL/bin:\$PATH
        npm install -g clawdbot
    "
else
    mkdir -p "$NPM_GLOBAL"
    npm config set prefix "$NPM_GLOBAL"
    export PATH="$NPM_GLOBAL/bin:$PATH"
    npm install -g clawdbot
fi

# Add to PATH permanently
PROFILE="/home/${CLAWD_USER}/.bashrc"
if ! grep -q "npm-global" "$PROFILE" 2>/dev/null; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$PROFILE"
fi

# ─────────────────────────────────────────────────────────────
# 5. Clone workspace
# ─────────────────────────────────────────────────────────────
echo ""
echo "📂 Setting up workspace..."
if [ ! -d "$CLAWD_DIR" ]; then
    if [ "$(whoami)" = "root" ]; then
        sudo -u "$CLAWD_USER" git clone "$CLAWD_REPO" "$CLAWD_DIR" || {
            echo "⚠️  Git clone failed (SSH key not set up?)"
            echo "   Creating empty workspace instead..."
            sudo -u "$CLAWD_USER" mkdir -p "$CLAWD_DIR"
        }
    else
        git clone "$CLAWD_REPO" "$CLAWD_DIR" || {
            echo "⚠️  Git clone failed, creating empty workspace..."
            mkdir -p "$CLAWD_DIR"
        }
    fi
else
    echo "   Workspace exists, pulling latest..."
    (cd "$CLAWD_DIR" && git pull) || true
fi

# ─────────────────────────────────────────────────────────────
# 6. Systemd service
# ─────────────────────────────────────────────────────────────
echo ""
echo "⚙️  Setting up systemd service..."

sudo tee /etc/systemd/system/clawdbot.service > /dev/null << EOF
[Unit]
Description=Clawdbot Gateway
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
Type=simple
User=${CLAWD_USER}
WorkingDirectory=${CLAWD_DIR}
ExecStart=${NPM_GLOBAL}/bin/clawdbot gateway start --foreground
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PATH=${NPM_GLOBAL}/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable clawdbot

# ─────────────────────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────────────────────
echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. sudo tailscale up --ssh     # Authenticate Tailscale"
echo "  2. Create ~/clawd/clawdbot.yaml with your config"
echo "  3. Set environment variables in /etc/environment or systemd override:"
echo "     ANTHROPIC_API_KEY=sk-..."
echo "  4. sudo systemctl start clawdbot"
echo "  5. sudo systemctl status clawdbot"
echo ""
echo "🕷️  The web awaits."
