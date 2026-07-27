Write-Host "=== Starting Backend (Cloudflare Workers) ===" -ForegroundColor Green
$backend = Start-Process -NoNewWindow -PassThru -FilePath "npm" -ArgumentList "run dev" -WorkingDirectory "backend"

Start-Sleep -Seconds 3

Write-Host "=== Starting Frontend (Flutter Web) ===" -ForegroundColor Green
$frontend = Start-Process -NoNewWindow -PassThru -FilePath "flutter" -ArgumentList "run -d chrome" -WorkingDirectory "frontend"

Write-Host ""
Write-Host "Both processes started. Close this window to stop both." -ForegroundColor Yellow
Write-Host "Backend: http://localhost:8787" -ForegroundColor Cyan
Write-Host "Frontend: Chrome will open automatically" -ForegroundColor Cyan

$backend.WaitForExit()
$frontend.WaitForExit()
