<#
    Install Lamplight on the phone WITHOUT destroying the vault.

    WHY THIS SCRIPT EXISTS

    `flutter run`, `flutter install` and Android Studio all fall back to
    uninstall-then-install when anything about the package identity changes —
    a different signing key, a different build variant, a downgraded version
    code. Uninstalling deletes /data/data/com.probablypiyush.lamplight, and
    that is where the vault lives. Every note, every recording, gone, with no
    prompt and no warning.

    That is not a hypothetical: it happened repeatedly during development and
    was mistaken for the app resetting itself. The app was never resetting
    anything. The install was a fresh install every time.

    So this script does the one thing that preserves data — `adb install -r`,
    which patches the existing app in place — and REFUSES rather than falling
    back to a wipe if that is not possible. If you genuinely want to start
    over, pass -Fresh and it will say exactly what it is about to destroy.

    Usage:
        .\tool\install.ps1              build a release APK and update in place
        .\tool\install.ps1 -Debug       the same, with the debug variant
        .\tool\install.ps1 -Fresh       uninstall first (DESTROYS the vault)
#>

param(
    [switch]$Debug,
    [switch]$Fresh
)

$ErrorActionPreference = 'Stop'
$package = 'com.probablypiyush.lamplight'
$root = Split-Path -Parent $PSScriptRoot

Push-Location $root
try {
    # ── Is a phone actually there? ───────────────────────────────────────────
    $devices = (& adb devices) | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' }
    if (-not $devices) {
        Write-Host 'No authorised device. Plug the phone in and accept the prompt.' -ForegroundColor Red
        exit 1
    }

    # ── Is it already installed, and does it hold anything? ──────────────────
    $installed = (& adb shell pm list packages $package) -match $package

    if ($Fresh) {
        if ($installed) {
            Write-Host ''
            Write-Host '  This will UNINSTALL Lamplight and permanently delete the vault on' -ForegroundColor Yellow
            Write-Host '  this phone: every entry, photo, voice note and document in it.' -ForegroundColor Yellow
            Write-Host '  There is no recovery. Make a backup first if you want one.' -ForegroundColor Yellow
            Write-Host ''
            $answer = Read-Host '  Type DELETE to continue'
            if ($answer -cne 'DELETE') {
                Write-Host 'Stopped. Nothing was changed.' -ForegroundColor Green
                exit 0
            }
            & adb uninstall $package | Out-Null
        }
    }

    # ── Build ────────────────────────────────────────────────────────────────
    $variant = if ($Debug) { 'debug' } else { 'release' }
    Write-Host "Building the $variant APK…" -ForegroundColor Cyan
    & C:\src\flutter\bin\flutter.bat build apk "--$variant"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $apk = Join-Path $root "build\app\outputs\flutter-apk\app-$variant.apk"
    if (-not (Test-Path $apk)) {
        Write-Host "No APK at $apk" -ForegroundColor Red
        exit 1
    }

    # ── Install, keeping the data ────────────────────────────────────────────
    #
    # -r replaces the existing app in place and leaves /data/data alone. It
    # fails rather than wiping if the signature differs, which is exactly the
    # behaviour we want: a refusal we can read beats a silent deletion.
    Write-Host 'Installing over the existing app…' -ForegroundColor Cyan
    $output = & adb install -r $apk 2>&1 | Out-String
    Write-Host $output

    if ($output -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE|signatures do not match') {
        Write-Host ''
        Write-Host '  REFUSED, and that is the script doing its job.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  The APK you just built is signed with a different key from the copy' -ForegroundColor Yellow
        Write-Host '  already on the phone, so Android will not update one with the other.' -ForegroundColor Yellow
        Write-Host '  Usually that means you have switched between debug and release.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  Your vault on the phone is untouched. Either rebuild the same variant' -ForegroundColor Yellow
        Write-Host '  you installed last time, or — if you truly want to start over —' -ForegroundColor Yellow
        Write-Host '  back up first and then run:  .\tool\install.ps1 -Fresh' -ForegroundColor Yellow
        exit 1
    }

    if ($LASTEXITCODE -ne 0 -or $output -notmatch 'Success') { exit 1 }

    Write-Host 'Installed. The vault on the phone was left alone.' -ForegroundColor Green
    & adb shell monkey -p $package -c android.intent.category.LAUNCHER 1 | Out-Null
}
finally {
    Pop-Location
}
