# MoSJE Nirikshan - Permanent Cloud Gateway Launcher
# Provides zero-config public HTTPS access for physical phone over 4G/5G mobile data or Wi-Fi

$localPort = 8000
$cloudflaredPath = "$PSScriptRoot\scratch\cloudflared.exe"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   MoSJE NIRIKSHAN - PERMANENT CLOUD GATEWAY              " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

if (Test-Path $cloudflaredPath) {
    Write-Host "[+] Starting Cloudflare Quick Tunnel on port $localPort..." -ForegroundColor Green
    Write-Host "This will generate a permanent public HTTPS URL that your phone can reach ANYWHERE." -ForegroundColor White
    & $cloudflaredPath tunnel --url "http://localhost:$localPort"
} else {
    Write-Host "[+] Cloudflared not ready, using Localtunnel fallback on port $localPort..." -ForegroundColor Yellow
    npx -y localtunnel --port $localPort
}
