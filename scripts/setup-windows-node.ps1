# ================================================================
# Windows Node Setup Script
# Configure Windows PC as a remote execution node for Linux gateway
# ================================================================

param(
    [string]$GatewayIP = "100.118.246.104",
    [string]$GatewayPort = "18789",
    [string]$AnthropicKey = ""
)

Write-Host "🕷️ Setting up Windows as a Node..." -ForegroundColor Green

# Stop any running gateway
Write-Host "[1/5] Stopping existing gateway..."
if (Test-Path "stop.ps1") {
    .\stop.ps1
}

# Configure .env for node mode (no Telegram bot token)
Write-Host "[2/5] Configuring environment..."
$envContent = @"
# ===========================================================
# Windows Node Configuration
# ===========================================================

# Anthropic API Key (required for node)
ANTHROPIC_API_KEY=$AnthropicKey

# Gateway connection (connect to Linux gateway)
CLAWDBOT_GATEWAY_URL=ws://${GatewayIP}:${GatewayPort}

# No Telegram bot token (nodes don't run bots)
# TELEGRAM_BOT_TOKEN=

"@

$envContent | Out-File -FilePath ".env" -Encoding utf8
Write-Host "✅ Updated .env" -ForegroundColor Green

# Create node configuration
Write-Host "[3/5] Creating node configuration..."
$nodeConfig = @"
{
    "mode": "node",
    "gateway": {
        "url": "ws://${GatewayIP}:${GatewayPort}"
    },
    "node": {
        "name": "work-pc",
        "capabilities": ["exec", "fs"]
    }
}
"@

$configDir = "$env:USERPROFILE\.clawdbot"
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$nodeConfig | Out-File -FilePath "$configDir\node.json" -Encoding utf8
Write-Host "✅ Created node configuration" -ForegroundColor Green

# Create node startup script
Write-Host "[4/5] Creating node startup script..."
$startScript = @"
# Start Windows Node
Write-Host "🕷️ Starting Windows Node..."

# Connect to main gateway as node
clawdbot node start --config `"$env:USERPROFILE\.clawdbot\node.json`"
"@

$startScript | Out-File -FilePath "start-node.ps1" -Encoding utf8
Write-Host "✅ Created start-node.ps1" -ForegroundColor Green

# Create stop script
Write-Host "[5/5] Creating stop script..."
$stopScript = @"
# Stop Windows Node
Write-Host "🕷️ Stopping Windows Node..."
clawdbot node stop
"@

$stopScript | Out-File -FilePath "stop-node.ps1" -Encoding utf8
Write-Host "✅ Created stop-node.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 Node setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Run: .\start-node.ps1"
Write-Host "2. Check connection from Linux: nodes status"
Write-Host ""
Write-Host "Gateway: ws://${GatewayIP}:${GatewayPort}"