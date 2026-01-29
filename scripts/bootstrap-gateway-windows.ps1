#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bootstrap Clawdbot Gateway on Windows
.DESCRIPTION
    One-shot setup: installs Node.js, Git, Clawdbot, clones workspace, sets up as service
.NOTES
    Run as Administrator in PowerShell:
    Set-ExecutionPolicy Bypass -Scope Process -Force; .\bootstrap-gateway-windows.ps1
#>

$ErrorActionPreference = "Stop"

# ─────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────
$CLAWD_USER = $env:USERNAME
$CLAWD_DIR = "$env:USERPROFILE\clawd"
$CLAWD_REPO = "https://github.com/brnsmd/clawd-workspace.git"
$SERVICE_NAME = "Clawdbot"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Broodbrother Gateway Bootstrap (Windows)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ─────────────────────────────────────────────────────────────
# 1. Check/Install winget
# ─────────────────────────────────────────────────────────────
Write-Host "[1/6] Checking package manager..." -ForegroundColor Yellow

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  winget not found. Please install App Installer from Microsoft Store." -ForegroundColor Red
    Write-Host "  https://apps.microsoft.com/store/detail/9NBLGGH4NNS1" -ForegroundColor Red
    exit 1
}
Write-Host "  winget OK" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────
# 2. Install Git
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/6] Installing Git..." -ForegroundColor Yellow

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "  Already installed" -ForegroundColor Green
}

# ─────────────────────────────────────────────────────────────
# 3. Install Node.js
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[3/6] Installing Node.js..." -ForegroundColor Yellow

if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    $nodeVersion = node --version
    Write-Host "  Already installed: $nodeVersion" -ForegroundColor Green
}

# Verify node is available
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "  Node.js installation requires restart. Please restart PowerShell and run again." -ForegroundColor Red
    exit 1
}

# ─────────────────────────────────────────────────────────────
# 4. Install Clawdbot
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[4/6] Installing Clawdbot..." -ForegroundColor Yellow

npm install -g clawdbot
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Failed to install clawdbot" -ForegroundColor Red
    exit 1
}
Write-Host "  Installed" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────
# 5. Clone workspace
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[5/6] Setting up workspace..." -ForegroundColor Yellow

if (!(Test-Path $CLAWD_DIR)) {
    git clone $CLAWD_REPO $CLAWD_DIR
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Clone failed, creating empty workspace..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $CLAWD_DIR -Force | Out-Null
    }
} else {
    Write-Host "  Workspace exists, pulling latest..." -ForegroundColor Green
    Push-Location $CLAWD_DIR
    git pull 2>$null
    Pop-Location
}

# ─────────────────────────────────────────────────────────────
# 6. Set up Windows Service using NSSM or Task Scheduler
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[6/6] Setting up auto-start..." -ForegroundColor Yellow

# Get clawdbot path
$clawdbotPath = (Get-Command clawdbot).Source

# Create a startup script
$startupScript = @"
@echo off
cd /d "$CLAWD_DIR"
"$clawdbotPath" gateway start --foreground
"@

$startupBat = "$CLAWD_DIR\start-gateway.bat"
Set-Content -Path $startupBat -Value $startupScript

# Option A: Task Scheduler (simpler, no extra tools)
$taskName = "ClawdbotGateway"
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

$action = New-ScheduledTaskAction -Execute $startupBat -WorkingDirectory $CLAWD_DIR
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId $CLAWD_USER -LogonType S4U -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Clawdbot Gateway - Always-on assistant"

Write-Host "  Created scheduled task: $taskName" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────
# Create environment file template
# ─────────────────────────────────────────────────────────────
$envFile = "$CLAWD_DIR\.env"
if (!(Test-Path $envFile)) {
    @"
# Clawdbot Environment Variables
# Fill these in and restart the gateway

ANTHROPIC_API_KEY=sk-ant-your-key-here
# TELEGRAM_BOT_TOKEN=your-telegram-token
# SLACK_APP_TOKEN=xapp-...
# SLACK_BOT_TOKEN=xoxb-...
"@ | Set-Content $envFile
    Write-Host ""
    Write-Host "  Created $envFile - EDIT THIS with your API keys!" -ForegroundColor Yellow
}

# ─────────────────────────────────────────────────────────────
# Done!
# ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "  Bootstrap Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Edit $CLAWD_DIR\.env with your API keys"
Write-Host "  2. Copy/create clawdbot.yaml config (see infra\clawdbot.yaml.template)"
Write-Host "  3. Test manually:"
Write-Host "       cd $CLAWD_DIR"
Write-Host "       clawdbot gateway start"
Write-Host "  4. Once working, start the scheduled task:"
Write-Host "       Start-ScheduledTask -TaskName ClawdbotGateway"
Write-Host "  5. Or just reboot - it will auto-start"
Write-Host ""
Write-Host "Tailscale IP (for remote access):" -ForegroundColor Cyan
tailscale ip -4 2>$null || Write-Host "  (run 'tailscale ip -4' to check)"
Write-Host ""
Write-Host "The web awaits." -ForegroundColor Magenta
