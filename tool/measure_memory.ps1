# What Lamplight is holding, and what killed it last time.
#
# ══ WHY THIS EXISTS ═════════════════════════════════════════════════════════
#
# `Honest Review/WHAT-LAMPLIGHT-LACKS.md` and `PLAN.md` both say the same
# thing: *"nothing in this project measures memory"*. Round fifteen diagnosed
# "THE APP IDK SUDDENLY CLOSES" as the low-memory killer and could not show
# the number, so the fix was guessed at rather than aimed.
#
# This is the number. It is READ-ONLY — every command below reads state and
# none of them install, launch, stop or clear anything. That is deliberate:
# `PLAN.md` §0 records that Flutter's own tooling destroyed a real vault on
# this project once, and nothing that measures should ever be able to.
#
# ══ WHAT TO LOOK AT ═════════════════════════════════════════════════════════
#
#   exit-info   why the process died last time. `reason=3 (LOW_MEMORY)` with
#               `state=empty` means it was killed while CACHED — nothing on
#               screen — which is the case that matters, because Android's LMK
#               takes the largest cached process first. Recorded on his phone
#               on 23 September 2026 at pss=257MB rss=338MB.
#
#   meminfo     where it is going right now. `Graphics` and `EGL mtrack` are
#               GPU textures; `Native Heap` is libsodium, SQLCipher and decoded
#               images; `Dart`/`Java Heap` is the app's own objects.
#
# ══ USAGE ═══════════════════════════════════════════════════════════════════
#
#   ./tool/measure_memory.ps1              # whatever is installed
#   ./tool/measure_memory.ps1 -Sandbox     # the .sandbox package instead

param(
    [switch]$Sandbox
)

$pkg = if ($Sandbox) { 'com.probablypiyush.lamplight.sandbox' }
       else { 'com.probablypiyush.lamplight' }

$adb = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adb) {
    $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
    if (Test-Path $sdk) { $adb = $sdk } else { throw 'adb not found.' }
} else { $adb = $adb.Source }

$devices = & $adb devices
if (($devices | Select-String '\sdevice$').Count -eq 0) {
    throw 'No device. Plug the phone in and allow USB debugging.'
}

Write-Output ''
Write-Output "package : $pkg"

# ── Is it even installed, and is the vault the same one? ────────────────────
#
# `ceDataInode` is the identity of /data/data for this package. If it changes,
# the vault was replaced -- which is the thing this project cares about most.
$pkgInfo = & $adb shell dumpsys package $pkg 2>$null
if (-not $pkgInfo) { throw "$pkg is not installed on this device." }

$version = ($pkgInfo | Select-String 'versionName=' | Select-Object -First 1) -replace '.*versionName=', ''
$code    = ($pkgInfo | Select-String 'versionCode='  | Select-Object -First 1) -replace '.*versionCode=(\d+).*', '$1'
$inode   = ($pkgInfo | Select-String 'ceDataInode='  | Select-Object -First 1) -replace '.*ceDataInode=(\d+).*', '$1'
Write-Output "installed: $($version.Trim())  (versionCode $($code.Trim()))"
Write-Output "ceDataInode: $($inode.Trim())   <- must not change across updates"

# ── How it died last time ───────────────────────────────────────────────────
Write-Output ''
Write-Output '--- how it ended, most recent first -------------------------'
$exits = & $adb shell dumpsys activity exit-info $pkg 2>$null
$lines = $exits | Select-String 'timestamp=|reason=|pss=' 
if ($lines) {
    $lines | Select-Object -First 9 | ForEach-Object { Write-Output ("  " + $_.ToString().Trim()) }
    if ($exits | Select-String 'reason=3 \(LOW_MEMORY\)') {
        Write-Output ''
        Write-Output '  >> LOW_MEMORY present. If state=empty, it was killed while cached:'
        Write-Output '     the fix is a smaller BACKGROUNDED footprint, not a smaller peak.'
    }
} else {
    Write-Output '  (no recorded exits)'
}

# ── What it is holding now ──────────────────────────────────────────────────
Write-Output ''
Write-Output '--- what it is holding now ----------------------------------'
# `pidof` exits non-zero when there is no process, which is not an error here —
# "not running" is a perfectly good answer. Swallowed so the script's own exit
# code means what it says.
$running = $null
try { $running = (& $adb shell pidof $pkg 2>$null) } catch {}
$global:LASTEXITCODE = 0
if (-not $running) {
    Write-Output '  not running. Open the app, then run this again.'
    Write-Output '  (Deliberately not launched from here: this script only reads.)'
} else {
    $mem = & $adb shell dumpsys meminfo $pkg 2>$null
    $mem | Select-String 'TOTAL PSS|Native Heap|Dart|Graphics|EGL mtrack|GL mtrack|TOTAL RSS' |
        ForEach-Object { Write-Output ("  " + $_.ToString().Trim()) }
}

Write-Output ''
Write-Output 'Nothing above modified the device.'
Write-Output ''

exit 0
