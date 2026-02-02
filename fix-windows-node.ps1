```powershell
# Windows Node Fix - Just Run This
Write-Host "🕷️ Fixing Windows Node..." -ForegroundColor Green

# Stop gateway
if (Test-Path "stop.ps1") { & .\stop.ps1 }

# Fix .env file
@"
ANTHROPIC_API_KEY=sk-ant-oat01-bz-RNN1Ij0PuBaY2OHR2SuyGzuGEw94vUJXsqoIfSDQmGLS-s7QV2yki4r4qYxNOOwQA6uhWm20HRCnTLElYYQ-HCfyQAA
"@ | Out-File -FilePath ".env" -Encoding utf8 -Force

Write-Host "✅ Fixed .env file" -ForegroundColor Green

# Show node options
clawdbot node --help
```