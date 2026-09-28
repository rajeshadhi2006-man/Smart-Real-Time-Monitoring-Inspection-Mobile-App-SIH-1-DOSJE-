# Auto-keeper for ADB Reverse port forwardings
# Ensures physical mobile device stays connected to localhost:8000 (FastAPI) and localhost:5173 (Web Dashboard)
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    Write-Error "adb.exe not found at $adb"
    exit 1
}

Write-Host "[Nirikshan ADB Sync] Monitoring USB ADB reverse connection for mobile device..." -ForegroundColor Cyan

while ($true) {
    try {
        $devs = (& $adb devices | Out-String)
        if ($devs -match '10BF3G0Q4A005B1\s+device' -or $devs -match '\bdevice\b') {
            $list = (& $adb reverse --list 2>$null | Out-String)
            if ($list -notmatch 'tcp:8000') {
                & $adb reverse tcp:8000 tcp:8000 | Out-Null
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Port 8000 reversed -> Mobile is ONLINE" -ForegroundColor Green
            }
            if ($list -notmatch 'tcp:5173') {
                & $adb reverse tcp:5173 tcp:5173 | Out-Null
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Port 5173 reversed -> Web Dashboard reachable" -ForegroundColor Green
            }
        }
    } catch {
        # ignore transient USB errors
    }
    Start-Sleep -Seconds 2
}
