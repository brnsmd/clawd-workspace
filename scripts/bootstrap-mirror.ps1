#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bootstrap Clawdbot Mirror Gateway on Windows
.DESCRIPTION
    Sets up a mirrored Clawdbot instance that syncs with home via git.
    Same workspace, same bot, manual handoff between locations.
.USAGE
    # One-liner (run as Admin in PowerShell):
    Set-ExecutionPolicy Bypass -Scope Process -Force; iwr -Uri "https://raw.githubusercontent.com/brnsmd/clawd-workspace/main/scripts/bootstrap-mirror.ps1" -OutFile "$env:TEMP\bootstrap.ps1"; & "$env:TEMP\bootstrap.ps1"
#>

param(
    [string]$GatewayRepo = "https://github.com/brnsmd/clawd-workspace.git",
    [string]$ClawdDir = "$env:USERPROFILE\clawd",
    [string]$NodeName = "work"
)

$ErrorActionPreference = "Stop"

function Write-Step($num, $total, $msg) {
    Write-Host ""
    Write-Host "[$num/$total] $msg" -ForegroundColor Yellow
}

function Write-Ok($msg) {
    Write-Host "  ✓ $msg" -ForegroundColor Green
}

function Write-Warn($msg) {
    Write-Host "  ⚠ $msg" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🕷️  Broodbrother Mirror Setup (Windows)  🕷️     ║" -ForegroundColor Cyan
Write-Host "║     Same brain, different body                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan

# ─────────────────────────────────────────────────────────────
# 1. Prerequisites check
# ─────────────────────────────────────────────────────────────
Write-Step 1 7 "Checking prerequisites..."

# Check winget
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  ✗ winget not found. Install App Installer from Microsoft Store:" -ForegroundColor Red
    Write-Host "    https://apps.microsoft.com/store/detail/9NBLGGH4NNS1" -ForegroundColor Red
    exit 1
}
Write-Ok "winget"

# ─────────────────────────────────────────────────────────────
# 2. Install Git
# ─────────────────────────────────────────────────────────────
Write-Step 2 7 "Installing Git..."

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Ok "git $(git --version)"
} else {
    Write-Warn "Git installed but needs terminal restart"
}

# ─────────────────────────────────────────────────────────────
# 3. Install Node.js
# ─────────────────────────────────────────────────────────────
Write-Step 3 7 "Installing Node.js..."

if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Ok "node $(node --version)"
} else {
    Write-Host "  ✗ Node.js needs terminal restart. Close and re-run this script." -ForegroundColor Red
    exit 1
}

# ─────────────────────────────────────────────────────────────
# 4. Install Tailscale (for connectivity)
# ─────────────────────────────────────────────────────────────
Write-Step 4 7 "Installing Tailscale..."

if (!(Get-Command tailscale -ErrorAction SilentlyContinue)) {
    winget install -e --id Tailscale.Tailscale --accept-source-agreements --accept-package-agreements
    Write-Warn "Tailscale installed - log in after setup: tailscale login"
} else {
    $tsStatus = tailscale status 2>&1
    if ($tsStatus -match "stopped") {
        Write-Warn "Tailscale installed but not running"
    } else {
        Write-Ok "Tailscale connected"
    }
}

# ─────────────────────────────────────────────────────────────
# 5. Install Clawdbot
# ─────────────────────────────────────────────────────────────
Write-Step 5 7 "Installing Clawdbot..."

$npmPrefix = npm config get prefix 2>$null
npm install -g clawdbot
if ($LASTEXITCODE -eq 0) {
    Write-Ok "clawdbot $(clawdbot --version)"
} else {
    Write-Host "  ✗ Failed to install clawdbot" -ForegroundColor Red
    exit 1
}

# ─────────────────────────────────────────────────────────────
# 6. Clone/sync workspace
# ─────────────────────────────────────────────────────────────
Write-Step 6 7 "Setting up workspace..."

if (!(Test-Path $ClawdDir)) {
    Write-Host "  Cloning workspace..." -ForegroundColor Gray
    git clone $GatewayRepo $ClawdDir
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Clone failed - creating fresh workspace"
        New-Item -ItemType Directory -Path $ClawdDir -Force | Out-Null
    }
    Write-Ok "Cloned to $ClawdDir"
} else {
    Write-Host "  Workspace exists, syncing..." -ForegroundColor Gray
    Push-Location $ClawdDir
    git fetch origin 2>$null
    git pull origin main 2>$null
    Pop-Location
    Write-Ok "Synced $ClawdDir"
}

# ─────────────────────────────────────────────────────────────
# 7. Create config and scripts
# ─────────────────────────────────────────────────────────────
Write-Step 7 7 "Creating configuration..."

# Node identity file
$nodeIdentity = "$ClawdDir\.clawdbot-node"
@"
{
  "name": "$NodeName",
  "type": "mirror",
  "created": "$(Get-Date -Format o)"
}
"@ | Set-Content $nodeIdentity
Write-Ok "Node identity: $NodeName"

# Environment template
$envFile = "$ClawdDir\.env"
if (!(Test-Path $envFile)) {
    @"
# Clawdbot API Keys
# Get from: https://console.anthropic.com/
ANTHROPIC_API_KEY=sk-ant-xxxxx

# Telegram Bot Token (same as home - shared bot!)
# Get from: @BotFather on Telegram
TELEGRAM_BOT_TOKEN=xxxxx

# Optional: Other services
# SLACK_APP_TOKEN=xapp-...
# SLACK_BOT_TOKEN=xoxb-...
"@ | Set-Content $envFile
    Write-Warn "Created .env template - EDIT WITH YOUR KEYS!"
} else {
    Write-Ok ".env exists"
}

# Sync script
$syncScript = "$ClawdDir\scripts\sync.ps1"
if (!(Test-Path "$ClawdDir\scripts")) {
    New-Item -ItemType Directory -Path "$ClawdDir\scripts" -Force | Out-Null
}
@'
# Sync workspace with git
param([switch]$Push, [switch]$Pull)

$ErrorActionPreference = "Stop"
Push-Location $PSScriptRoot\..

if ($Pull -or (!$Push -and !$Pull)) {
    Write-Host "Pulling latest..." -ForegroundColor Cyan
    git pull origin main
}

if ($Push) {
    Write-Host "Pushing changes..." -ForegroundColor Cyan
    git add -A
    $msg = "sync from $env:COMPUTERNAME @ $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git commit -m $msg 2>$null
    git push origin main
}

Pop-Location
Write-Host "Done!" -ForegroundColor Green
'@ | Set-Content $syncScript

# Start script
$startScript = "$ClawdDir\start.ps1"
@"
# Start Clawdbot Gateway
Push-Location `$PSScriptRoot
Write-Host "Syncing workspace..." -ForegroundColor Cyan
& .\scripts\sync.ps1 -Pull
Write-Host "Starting gateway..." -ForegroundColor Cyan
clawdbot gateway start
Pop-Location
"@ | Set-Content $startScript

# Stop script
$stopScript = "$ClawdDir\stop.ps1"
@"
# Stop Clawdbot Gateway and sync
Push-Location `$PSScriptRoot
Write-Host "Stopping gateway..." -ForegroundColor Cyan
clawdbot gateway stop
Write-Host "Syncing workspace..." -ForegroundColor Cyan
& .\scripts\sync.ps1 -Push
Pop-Location
"@ | Set-Content $stopScript

Write-Ok "Created start.ps1, stop.ps1, scripts\sync.ps1"

# ─────────────────────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✓ Mirror Setup Complete!                         ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Edit API keys:" -ForegroundColor White
Write-Host "     notepad $ClawdDir\.env" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Log into Tailscale:" -ForegroundColor White
Write-Host "     tailscale login" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Test the gateway:" -ForegroundColor White
Write-Host "     cd $ClawdDir" -ForegroundColor Gray
Write-Host "     .\start.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. From Telegram, use:" -ForegroundColor White
Write-Host "     /handoff work  - switch to this PC" -ForegroundColor Gray
Write-Host "     /handoff home  - switch back home" -ForegroundColor Gray
Write-Host ""
Write-Host "Tailscale IP:" -ForegroundColor Cyan
tailscale ip -4 2>$null
Write-Host ""
Write-Host "The web grows. 🕷️" -ForegroundColor Magenta
