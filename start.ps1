Push-Location E:\clawd
Write-Host "Syncing..." -ForegroundColor Cyan
& .\scripts\sync.ps1 -Pull
Write-Host "Starting Broodbrother..." -ForegroundColor Green
clawdbot gateway start
Pop-Location
