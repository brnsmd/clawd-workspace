#!/bin/bash
# BOOM-BAP Windows Node Setup Script
# One command to rule them all

set -e

WINDOWS_NODE_NAME="work-pc"
WINDOWS_TAILSCALE_IP="100.74.125.9"
LINUX_TAILSCALE_IP="100.118.246.104"
GATEWAY_PORT="18789"

echo "🕷️ BROODMOTHER BOOM-BAP WINDOWS NODE SETUP"
echo "========================================="

echo "[1/5] Configuring Linux gateway for LAN binding..."
clawdbot gateway config.patch '{
  "gateway": {
    "bind": "lan",
    "tailscale": {
      "mode": "off"
    }
  },
  "tools": {
    "exec": {
      "host": "node",
      "security": "full", 
      "ask": "off",
      "node": "work-pc"
    }
  }
}'

echo "[2/5] Waiting for gateway restart..."
sleep 5

echo "[3/5] Sending Windows node configuration commands..."
clawdbot message send telegram:227230975 "🕷️ EXECUTE BOOM-BAP SETUP:

mkdir \"\$env:USERPROFILE\\.clawdbot\" -Force
@\"
{
  \"nodeHost\": {
    \"execApprovals\": {
      \"mode\": \"allow-all\",
      \"autoApprove\": true
    }
  }
}
\"@ | Out-File \"\$env:USERPROFILE\\.clawdbot\\node.json\" -Encoding utf8

clawdbot gateway stop
clawdbot node install --config \"\$env:USERPROFILE\\.clawdbot\\node.json\"
clawdbot node restart

Reply BOOM-BAP-COMPLETE when done."

echo "[4/5] Waiting for Windows node setup..."
echo "Monitoring for node connection..."

# Wait for node to connect
for i in {1..30}; do
    if clawdbot nodes status | grep -q "work-pc.*connected.*true"; then
        echo "✅ Windows node connected!"
        break
    fi
    echo "  Waiting for node... ($i/30)"
    sleep 2
done

echo "[5/5] Testing remote execution..."
if clawdbot exec 'echo "BOOM-BAP SUCCESS! 🕷️"' | grep -q "BOOM-BAP SUCCESS"; then
    echo "🎉 BOOM-BAP COMPLETE! Windows node ready for action!"
    echo ""
    echo "Usage:"
    echo "  clawdbot exec 'dir'"
    echo "  clawdbot exec 'powershell Get-Process'"
    echo "  clawdbot exec 'hostname'"
    echo ""
    echo "Your Windows PC is now your remote execution slave! 🕷️"
else
    echo "❌ BOOM-BAP FAILED! Node connected but commands not working."
    echo "Check approvals manually."
fi