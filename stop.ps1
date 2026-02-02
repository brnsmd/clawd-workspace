Push-Location E:\clawd
Write-Host "Stopping Broodbrother..." -ForegroundColor Yellow
clawdbot gateway stop
Write-Host "Syncing..." -ForegroundColor Cyan
& .\scripts\sync.ps1 -Push
Pop-Location
