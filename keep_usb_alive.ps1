# USB Reverse Auto-Maintainer Daemon
# Automatically re-establishes 'adb reverse tcp:8000 tcp:8000' every 5 seconds
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbPath = (Get-Command adb -ErrorAction SilentlyContinue).Source
}

Write-Host "[USB DAEMON] Monitoring USB connection for port 8000 forwarding..." -ForegroundColor Cyan

while ($true) {
    try {
        $devs = & $adbPath devices | Select-String "device$"
        if ($devs) {
            $reversed = & $adbPath reverse --list | Select-String "8000"
            if (-not $reversed) {
                & $adbPath reverse tcp:8000 tcp:8000 | Out-Null
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [USB] Re-established reverse tcp:8000 -> tcp:8000" -ForegroundColor Green
            }
        }
    } catch {}
    Start-Sleep -Seconds 5
}
