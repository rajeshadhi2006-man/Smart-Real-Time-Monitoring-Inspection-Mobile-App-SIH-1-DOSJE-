# Automated Phone Installer & Bridge for SIH Inspection App
# Specifically configured for Vivo Y29 5G and physical Android phones

$adbPath = "C:\Users\Rajesh s\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) {
        $adbPath = $adbCmd.Source
    } else {
        Write-Host "[!] Error: adb.exe not found at $adbPath" -ForegroundColor Red
        exit 1
    }
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     MoSJE NIRIKSHAN 2.0 - PHONE INSTALLER & SYNC         " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check connected ADB devices
Write-Host "`n[1/4] Checking connected Android devices..." -ForegroundColor White
$devicesOutput = & $adbPath devices -l
Write-Host $devicesOutput

$deviceLines = ($devicesOutput -split "`n") | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices" }

if (-not $deviceLines) {
    Write-Host "`n[!] No device detected via ADB." -ForegroundColor Yellow
    Write-Host "If your Vivo Y29 5G is connected via USB, please enable USB Debugging:" -ForegroundColor Cyan
    Write-Host "  1. Go to Settings > About phone > Software information."
    Write-Host "  2. Tap 'Build number' 7 times until it says 'You are now a developer!'."
    Write-Host "  3. Go to Settings > System > Developer options."
    Write-Host "  4. Turn ON 'USB debugging'."
    Write-Host "  5. On Vivo phones, also turn ON 'Install via USB'."
    Write-Host "  6. When the popup 'Allow USB debugging?' appears on your phone screen, tap 'Allow'."
    Write-Host "`nWaiting for device to connect (Press Ctrl+C to cancel)..." -ForegroundColor White

    while (-not $deviceLines) {
        Start-Sleep -Seconds 2
        $devicesOutput = & $adbPath devices -l
        $deviceLines = ($devicesOutput -split "`n") | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices" }
    }
    Write-Host "[+] Phone successfully detected via ADB!" -ForegroundColor Green
}

# 2. Reverse port 8000 for USB & Enable Wireless ADB
Write-Host "`n[2/4] Setting up reverse TCP port 8000 & Wireless Bridge..." -ForegroundColor White
& $adbPath reverse tcp:8000 tcp:8000
& $adbPath tcpip 5555
Write-Host "[+] Port 8000 reversed successfully." -ForegroundColor Green
Write-Host "[+] Wireless ADB port 5555 opened. You can now disconnect USB cable anytime!" -ForegroundColor Green

# 3. Detect current PC Wi-Fi IP dynamically
$wifiIp = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*" -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "169.*" } | Select-Object -First 1 -ExpandProperty IPAddress)
if (-not $wifiIp) {
    $wifiIp = "10.77.108.231"
}

# 4. Install APK
$apkPath = "$PSScriptRoot\build\app\outputs\flutter-apk\app-debug.apk"
if (-not (Test-Path $apkPath)) {
    $apkPath = "$PSScriptRoot\build\app\outputs\apk\debug\app-debug.apk"
}
if (Test-Path $apkPath) {
    Write-Host "`n[3/4] Installing updated APK on your phone ($apkPath)..." -ForegroundColor White
    & $adbPath install -r -d $apkPath
    Write-Host "[+] App installed successfully on your phone!" -ForegroundColor Green
} else {
    Write-Host "`n[!] APK not found at $apkPath. Please build it first with 'flutter build apk --debug'." -ForegroundColor Yellow
}

# 5. Launch App
Write-Host "`n[4/4] Launching MoSJE Nirikshan App on your phone..." -ForegroundColor White
& $adbPath shell am start -n in.gov.mosje.sih_inspection/.MainActivity
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "   APP IS READY ON YOUR PHONE!                            " -ForegroundColor Green
Write-Host "   - Connected via USB loopback: http://127.0.0.1:8000     " -ForegroundColor Cyan
Write-Host "   - Or over Wi-Fi LAN:          http://$($wifiIp):8000    " -ForegroundColor Cyan
Write-Host "   - Wireless ADB active:        adb connect <phone-ip>:5555" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green

