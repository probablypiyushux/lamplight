# ─────────────────────────────────────────────────────────────────────────────
#  shot.ps1 — pulls the phone's screen onto the laptop.
#
#  Takes whatever is on the phone's screen right now and drops it in
#  E:\Lamplight\shots\ as a PNG, where Claude can read it directly. That is
#  the point: without this you would have to screenshot on the phone, find
#  the file, and carry it across to the laptop by hand every time.
#
#  NEEDS **Settings -> Locking and security -> Allow screenshots** TO BE ON.
#  It is off by default, on every build. With FLAG_SECURE set Android hands
#  back a black rectangle instead of the screen, and this script says so.
#
#  Until 22 Aug 2026 this needed a *debug* build instead — the SCREENSHOT_HOLE
#  block in MainActivity.kt, now gone. See CLOSE-SCREENSHOT-HOLE.md. The switch
#  is better because a debug build runs under the JIT with assertions on, so
#  what you photographed was never the app you were judging.
#
#  Usage, from anywhere:
#      powershell -ExecutionPolicy Bypass -File E:\Lamplight\tool\shot.ps1
#      powershell -ExecutionPolicy Bypass -File E:\Lamplight\tool\shot.ps1 day-screen
#
#  The optional name is only there so the files are findable later.
# ─────────────────────────────────────────────────────────────────────────────

param(
    [string]$Name = ""
)

$ErrorActionPreference = "Stop"

# adb is not on PATH on this laptop, so look where the SDK actually put it
# before giving up. Order: PATH, then the two environment variables the SDK
# sets, then the default install location.
function Find-Adb {
    $onPath = Get-Command adb -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }

    $candidates = @(
        "$env:ANDROID_HOME\platform-tools\adb.exe",
        "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

$adb = Find-Adb
if (-not $adb) {
    Write-Host "Could not find adb.exe. Expected it at:" -ForegroundColor Red
    Write-Host "  $env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    exit 1
}

# "adb devices" prints a header line and then one line per device. A device
# that is plugged in but not authorised says "unauthorized" — worth catching,
# because the failure two steps later is cryptic.
$lines = & $adb devices
$attached = @()
foreach ($line in $lines) {
    if ($line -match "^\S+\s+(device|unauthorized|offline)$") { $attached += $line }
}
if ($attached.Count -eq 0) {
    Write-Host "No phone is connected. Plug it in and unlock it." -ForegroundColor Red
    exit 1
}
if ($attached -join " " -match "unauthorized") {
    Write-Host "The phone is connected but not authorised." -ForegroundColor Red
    Write-Host "Unlock it and tap 'Allow' on the USB debugging prompt."
    exit 1
}

$root  = Split-Path -Parent $PSScriptRoot
$shots = Join-Path $root "shots"
if (-not (Test-Path $shots)) { New-Item -ItemType Directory -Path $shots | Out-Null }

$stamp = Get-Date -Format "MMdd-HHmmss"
if ($Name -ne "") {
    $slug = $Name -replace '[^A-Za-z0-9\-_]', '-'
    $file = "$stamp-$slug.png"
} else {
    $file = "$stamp.png"
}
$dest = Join-Path $shots $file

# Capture on the phone, then pull. The obvious one-liner —
# `adb exec-out screencap -p > file.png` — corrupts the PNG under Windows
# PowerShell 5.1, because the redirect runs the bytes through a text encoder.
# Two extra round trips is a fair price for a file that opens.
$remote = "/sdcard/lamplight-shot.png"
& $adb shell screencap -p $remote
& $adb pull $remote "$dest" | Out-Null
& $adb shell rm -f $remote

if (-not (Test-Path $dest)) {
    Write-Host "The capture failed and no file was written." -ForegroundColor Red
    exit 1
}

$size = (Get-Item $dest).Length

# A screen that is genuinely all black compresses to almost nothing. That is
# what FLAG_SECURE produces, so a tiny file almost always means the running
# "Allow screenshots" is off rather than the screen being dark.
if ($size -lt 30000) {
    Write-Host ""
    Write-Host "Saved, but it is only $([math]::Round($size/1KB,1)) KB — that usually means a black frame." -ForegroundColor Yellow
    Write-Host "FLAG_SECURE is probably still set. Stop the app and run it again with"
    Write-Host "'flutter run' so the Kotlin change is actually compiled in — hot reload"
    Write-Host "does not rebuild the Android side."
    Write-Host ""
}

Write-Host $dest
