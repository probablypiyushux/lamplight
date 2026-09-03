# Raises the version in the two places that must never disagree.
#
# ══ WHY THIS IS A SCRIPT AND NOT AN INSTRUCTION ═════════════════════════════
#
# The version lives in `app/pubspec.yaml` (which is what Android actually
# ships) and in `app/lib/core/app_info.dart` (which is what the backup header,
# the Settings row and the copyable failure report say). Those two drifting
# apart is not a cosmetic bug: a `.vault` written in 2026 would name a build
# that never existed, and the person opening it in 2035 has no way to tell.
#
# `app/test/app_info_test.dart` fails when they drift — but a test that fails
# after the fact still costs a build. Doing both edits in one command means
# they cannot drift in the first place.
#
# ══ THE RULE ════════════════════════════════════════════════════════════════
#
#   Every artefact that leaves this laptop increments the build number.
#
# Not every commit. Every APK. The reasons are written out at length in
# `app/lib/core/app_info.dart`, and the short version is that Android refuses
# an update whose versionCode is not higher than the installed one, and the
# Play Store retires a versionCode permanently once it has seen it.
#
# ══ USAGE ═══════════════════════════════════════════════════════════════════
#
#   ./tool/bump_version.ps1              # build number only: 0.2.0+2 -> 0.2.0+3
#   ./tool/bump_version.ps1 -Patch       # 0.2.0+2 -> 0.2.1+3
#   ./tool/bump_version.ps1 -Minor       # 0.2.0+2 -> 0.3.0+3
#   ./tool/bump_version.ps1 -Major       # 0.2.0+2 -> 1.0.0+3
#
# The build number always increments, whichever of those is used. That is the
# part Android cares about; the rest is for people.

param(
    [switch]$Major,
    [switch]$Minor,
    [switch]$Patch,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$root    = Split-Path -Parent $PSScriptRoot
$pubspec = Join-Path $root 'app\pubspec.yaml'
$infoDart= Join-Path $root 'app\lib\core\app_info.dart'

foreach ($f in @($pubspec, $infoDart)) {
    if (-not (Test-Path $f)) { throw "not found: $f" }
}

# ── Read and write as UTF-8 without a BOM, by hand ──────────────────────────
#
# ══ THIS SCRIPT HIT THE EXACT BUG IT HAD A COMMENT WARNING ABOUT ════════════
#
# The first version used `Get-Content -Raw` and `Set-Content -Encoding utf8`,
# with a note further down saying to be careful about encoding because
# `make_release_key.ps1` had already cost this project a day over a byte-order
# mark. It then did both halves wrong on its first real run:
#
#   * `Get-Content` in Windows PowerShell 5.1 decodes with the **system ANSI
#     codepage** unless told otherwise, so every em dash in `app_info.dart`
#     came back as three mojibake characters and was written back that way.
#   * `Set-Content -Encoding utf8` in 5.1 writes UTF-8 **with a BOM**, and a
#     BOM at the top of `pubspec.yaml` is exactly what broke the first signed
#     build in August.
#
# .NET's own reader and writer take explicit encodings and do neither. The
# `$false` is "no BOM".
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, $utf8)
}

function Write-Utf8([string]$path, [string]$text) {
    [System.IO.File]::WriteAllText($path, $text, $utf8)
}

# ── Read the current version out of pubspec, which is the source of truth ──
$pubText = Read-Utf8 $pubspec
$m = [regex]::Match($pubText, '(?m)^version:[ \t]*(\d+)\.(\d+)\.(\d+)\+(\d+)[ \t]*$')
if (-not $m.Success) {
    throw "pubspec.yaml has no `version: X.Y.Z+N` line to raise."
}

$maj   = [int]$m.Groups[1].Value
$min   = [int]$m.Groups[2].Value
$pat   = [int]$m.Groups[3].Value
$build = [int]$m.Groups[4].Value

$was = "$maj.$min.$pat+$build"

# ── Raise it ────────────────────────────────────────────────────────────────
# Only one of the three may be given; more than one is almost certainly a
# mistake and silently picking the largest would hide it.
$flags = @($Major, $Minor, $Patch) | Where-Object { $_ }
if ($flags.Count -gt 1) {
    throw "Pass at most one of -Major, -Minor, -Patch."
}

if     ($Major) { $maj++; $min = 0; $pat = 0 }
elseif ($Minor) { $min++; $pat = 0 }
elseif ($Patch) { $pat++ }

# Always. This is the whole point of the script.
$build++

$now = "$maj.$min.$pat+$build"
$version = "$maj.$min.$pat"

if ($WhatIf) {
    Write-Host "would raise  $was  ->  $now"
    exit 0
}

# ── Write both files ────────────────────────────────────────────────────────

$pubNew = [regex]::Replace(
    $pubText,
    '(?m)^version:[ \t]*\d+\.\d+\.\d+\+\d+[ \t]*$',
    "version: $now")
Write-Utf8 $pubspec $pubNew

$infoText = Read-Utf8 $infoDart
$infoNew = [regex]::Replace(
    $infoText,
    "const String kAppVersion = '\d+\.\d+\.\d+';",
    "const String kAppVersion = '$version';")
$infoNew = [regex]::Replace(
    $infoNew,
    'const int kAppBuild = \d+;',
    "const int kAppBuild = $build;")

if ($infoNew -eq $infoText) {
    throw "app_info.dart was not changed - its constants may have been renamed."
}
Write-Utf8 $infoDart $infoNew

Write-Host "raised  $was  ->  $now"
Write-Host ""
Write-Host "Now:  cd app; flutter test test/app_info_test.dart"
Write-Host "      and commit both files together."
