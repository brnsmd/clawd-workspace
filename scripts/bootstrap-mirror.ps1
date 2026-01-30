#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bootstrap Clawdbot Mirror Gateway on Windows (E: drive)
.USAGE
    Set-ExecutionPolicy Bypass -Scope Process -Force; iwr -Uri "https://raw.githubusercontent.com/brnsmd/clawd-workspace/main/scripts/bootstrap-mirror.ps1" -OutFile "$env:TEMP\bootstrap.ps1"; & "$env:TEMP\bootstrap.ps1"
#>

param(
    [string]$GatewayRepo = "https://github.com/brnsmd/clawd-workspace.git",
    [string]$ClawdDir = "E:\clawd",
    [string]$NodeName = "work"
)

$ErrorActionPreference = "Stop"

function Write-Step($num, $total, $msg) {
    Write-Host ""
    Write-Host "[$num/$total] $msg" -ForegroundColor Yellow
}

function Write-Ok($msg) {
    Write-Host "  [OK] $msg" -ForegroundColor Green
}

function Write-Skip($msg) {
    Write-Host "  [SKIP] $msg (already installed)" -ForegroundColor Cyan
}

function Write-Warn($msg) {
    Write-Host "  [WARN] $msg" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "    Broodbrother Mirror Setup (Windows)                 " -ForegroundColor Cyan
Write-Host "    Same brain, different body                          " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Target: $ClawdDir" -ForegroundColor Gray

# ---------------------------------------------------------------
# 1. Check Git
# ---------------------------------------------------------------
Write-Step 1 5 "Checking Git..."

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVer = git --version 2>&1
    Write-Skip "git - $gitVer"
} else {
    Write-Host "  Installing Git..." -ForegroundColor Gray
    winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Ok "git installed"
    } else {
        Write-Host "  [ERROR] Git needs terminal restart" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------------
# 2. Check Node.js
# ---------------------------------------------------------------
Write-Step 2 5 "Checking Node.js..."

if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVer = node --version
    Write-Skip "node $nodeVer"
} else {
    Write-Host "  Installing Node.js..." -ForegroundColor Gray
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    if (Get-Command node -ErrorAction SilentlyContinue) {
        Write-Ok "node installed"
    } else {
        Write-Host "  [ERROR] Node.js needs terminal restart. Re-run script after." -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------------
# 3. Check Tailscale
# ---------------------------------------------------------------
Write-Step 3 5 "Checking Tailscale..."

if (Get-Command tailscale -ErrorAction SilentlyContinue) {
    $tsIP = tailscale ip -4 2>&1
    if ($tsIP -match "^\d+\.\d+\.\d+\.\d+") {
        Write-Skip "tailscale - $tsIP"
    } else {
        Write-Skip "tailscale (not logged in - run: tailscale login)"
    }
} else {
    Write-Host "  Installing Tailscale..." -ForegroundColor Gray
    winget install -e --id Tailscale.Tailscale --accept-source-agreements --accept-package-agreements
    Write-Warn "Tailscale installed - run: tailscale login"
}

# ---------------------------------------------------------------
# 4. Install Clawdbot + Clone workspace
# ---------------------------------------------------------------
Write-Step 4 5 "Setting up Clawdbot..."

# Install clawdbot globally
if (!(Get-Command clawdbot -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing clawdbot..." -ForegroundColor Gray
    npm install -g clawdbot
}
$clawdVer = clawdbot --version 2>&1
Write-Ok "clawdbot $clawdVer"

# Clone or update workspace
if (!(Test-Path $ClawdDir)) {
    Write-Host "  Cloning workspace to $ClawdDir..." -ForegroundColor Gray
    git clone $GatewayRepo $ClawdDir
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Clone failed - creating fresh workspace"
        New-Item -ItemType Directory -Path $ClawdDir -Force | Out-Null
    }
} else {
    Write-Host "  Workspace exists, pulling latest..." -ForegroundColor Gray
    Push-Location $ClawdDir
    git pull origin main 2>$null
    Pop-Location
}
Write-Ok "Workspace: $ClawdDir"

# ---------------------------------------------------------------
# 5. Create config files
# ---------------------------------------------------------------
Write-Step 5 5 "Creating configuration..."

# Ensure scripts folder exists
if (!(Test-Path "$ClawdDir\scripts")) {
    New-Item -ItemType Directory -Path "$ClawdDir\scripts" -Force | Out-Null
}

# Node identity
$nodeIdentity = "$ClawdDir\.clawdbot-node"
$nodeJson = '{"name": "' + $NodeName + '", "type": "mirror", "created": "' + (Get-Date -Format o) + '"}'
Set-Content -Path $nodeIdentity -Value $nodeJson

# Environment file with actual keys
$envFile = "$ClawdDir\.env"
$envContent = @"
# ===========================================================
# Broodbrother Environment - WORK PC
# ===========================================================

# Anthropic (for Claude) - Option 1: API Key
# Get from: https://console.anthropic.com/settings/keys
ANTHROPIC_API_KEY=

# Anthropic - Option 2: Use OAuth instead (recommended)
# After setup, run: clawdbot auth
# This will open browser to authenticate

# Telegram Bot Token (SAME bot as home!)
TELEGRAM_BOT_TOKEN=8448546128:AAEb-GAEX4sqFyzNdwvFO1wFWvWhuPPtKsM

# ===========================================================
"@
Set-Content -Path $envFile -Value $envContent

# Sync script
$syncContent = @'
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
    git commit -m "sync from $env:COMPUTERNAME @ $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>$null
    git push origin main
}
Pop-Location
'@
Set-Content -Path "$ClawdDir\scripts\sync.ps1" -Value $syncContent

# Start script
$startContent = @"
Push-Location $ClawdDir
Write-Host "Syncing..." -ForegroundColor Cyan
& .\scripts\sync.ps1 -Pull
Write-Host "Starting Broodbrother..." -ForegroundColor Green
clawdbot gateway start
Pop-Location
"@
Set-Content -Path "$ClawdDir\start.ps1" -Value $startContent

# Stop script  
$stopContent = @"
Push-Location $ClawdDir
Write-Host "Stopping Broodbrother..." -ForegroundColor Yellow
clawdbot gateway stop
Write-Host "Syncing..." -ForegroundColor Cyan
& .\scripts\sync.ps1 -Push
Pop-Location
"@
Set-Content -Path "$ClawdDir\stop.ps1" -Value $stopContent

Write-Ok "Created start.ps1, stop.ps1, .env"

# ---------------------------------------------------------------
# Done - Open .env for editing
# ---------------------------------------------------------------
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "    Setup Complete!                                     " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Telegram token: Already filled!" -ForegroundColor Green
Write-Host ""
Write-Host "  For Anthropic, choose ONE:" -ForegroundColor Cyan
Write-Host "    A: Add API key to .env (opening now...)" -ForegroundColor White
Write-Host "    B: Run: clawdbot auth (uses browser OAuth)" -ForegroundColor White
Write-Host ""
Write-Host "  Then test:" -ForegroundColor Cyan
Write-Host "    cd $ClawdDir" -ForegroundColor Gray
Write-Host "    .\start.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  Home Tailscale IP: 100.118.246.104" -ForegroundColor Magenta
Write-Host ""

# Open .env in notepad
Start-Process notepad.exe -ArgumentList $envFile

Write-Host "Opening .env for editing..." -ForegroundColor Yellow
