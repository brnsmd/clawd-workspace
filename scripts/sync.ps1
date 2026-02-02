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
