# Refuses to let a development build near a device that holds a real vault.
#
# ══ WHY THIS EXISTS ═════════════════════════════════════════════════════════
#
# On 28 August 2026 a vault on the Redmi Pad was destroyed by a command that
# was trying to be safe. The sequence, from logcat, in under a second:
#
#   00:54:13.394  PackageInstallerSession: Marking session failed:
#                 INSTALL_FAILED_USER_RESTRICTED: Install canceled by user
#   00:54:13.734  adbd: 'cmd package uninstall com.probablypiyush.lamplight'
#   00:54:13.762  PackageManager: Uninstall pkg: ... u0 flags:2
#
# `flags:2` is not DELETE_KEEP_DATA. With `allowBackup="false"`, that took
# /data/data/com.probablypiyush.lamplight with it.
#
# **Nobody typed that uninstall.** `flutter test integration_test -d <device>`
# built a debug APK, MIUI refused the install, and the Flutter tooling's
# failure path ran `adb uninstall` on the applicationId it tracks. That is the
# un-suffixed one, so an `applicationIdSuffix` added *specifically to keep dev
# builds away from the real app* was what pointed the uninstall at it.
#
# PLAN.md §0 already said "never `adb uninstall`". It was obeyed by the person
# and ignored by the tool. A sentence in a document cannot defend against this;
# a check that runs first can.
#
# ── WHAT IT DOES ───────────────────────────────────────────────────────────
#
# Reads the connected device and reports whether the release package is
# installed and how big its vault is. Exits non-zero if there is anything to
# lose, so it can gate a script:
#
#   ./tool/check_device_safe.ps1; if ($?) { flutter run }
#
# ── WHAT IT DELIBERATELY DOES NOT DO ───────────────────────────────────────
#
# It never installs, never uninstalls, and never writes to the device. It reads
# `dumpsys` and stops. A safety check that can itself change something is not a
# safety check.

param(
    # Skip the refusal and only report. For when you know the device is a spare.
    [switch]$ReportOnly
)

$ErrorActionPreference = 'Stop'
$package = 'com.probablypiyush.lamplight'

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
    $found = Get-Command adb -ErrorAction SilentlyContinue
    if ($null -eq $found) {
        Write-Host 'adb not found. Nothing to check, and nothing can be installed either.'
        exit 0
    }
    $adb = $found.Source
}

$devices = & $adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' }
if ($devices.Count -eq 0) {
    Write-Host 'No device attached. Safe.'
    exit 0
}

$unsafe = $false

foreach ($line in $devices) {
    $serial = ($line -split '\s+')[0]
    $model = (& $adb -s $serial shell getprop ro.product.model).Trim()

    Write-Host ''
    Write-Host "device   : $serial ($model)"

    $dump = & $adb -s $serial shell dumpsys package $package 2>$null
    if ($LASTEXITCODE -ne 0 -or ($dump -join "`n") -match 'Unable to find package') {
        Write-Host "$package : not installed"
        Write-Host 'verdict  : SAFE - there is no vault on this device to lose.'
        continue
    }

    $inode = ($dump | Select-String -Pattern 'ceDataInode=(\d+)').Matches.Groups[1].Value
    $version = ($dump | Select-String -Pattern 'versionName=(\S+)' | Select-Object -First 1)
    $installed = ($dump | Select-String -Pattern 'firstInstallTime=(.+)' | Select-Object -First 1)

    Write-Host "$package : INSTALLED"
    Write-Host "  $version"
    Write-Host "  $installed"
    Write-Host "  ceDataInode=$inode   <- record this; it must not change"

    $unsafe = $true

    Write-Host ''
    Write-Host 'verdict  : REFUSED - this device holds a real vault.' -ForegroundColor Red
    Write-Host ''
    Write-Host '  Anything that installs, including `flutter run`, `flutter test'
    Write-Host '  integration_test` and `flutter drive`, can uninstall this package'
    Write-Host '  as part of its own failure handling. An uninstall destroys the'
    Write-Host '  vault, because allowBackup is false and that is deliberate.'
    Write-Host ''
    Write-Host '  Before doing anything on this device:'
    Write-Host '    1. Open Lamplight, Settings -> Backup, and write a .vault to a'
    Write-Host '       folder OUTSIDE the app - Download is fine. Check it is there.'
    Write-Host '    2. Only then install, and only with:'
    Write-Host '         adb install -r <properly-signed-release.apk>'
    Write-Host '       never a debug build, never without -r, never uninstall.'
    Write-Host '    3. Afterwards, confirm ceDataInode is still' $inode
    Write-Host ''
}

if ($unsafe -and -not $ReportOnly) { exit 1 }
exit 0
