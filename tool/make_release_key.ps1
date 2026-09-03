# Lamplight -- make the release signing key.
#
# -----------------------------------------------------------------------------
#  PIYUSH RUNS THIS. NOBODY ELSE, AND NO TOOL.
# -----------------------------------------------------------------------------
#
#  This script creates a secret. PLAN.md 12 is explicit -- "this is Piyush's
#  to do; it involves a secret and the tooling must never handle one" -- and
#  android/app/build.gradle.kts is written so that a missing key.properties
#  falls back to the debug key rather than tempting anybody to generate one
#  automatically.
#
#  There is a practical reason on top of the rule. Read-Host below needs a
#  terminal. Claude's shell runs non-interactive with stdin on the null
#  device, so this script cannot even be run that way -- and if it could, the
#  password would pass through a transcript, which is the one place a signing
#  key's password must never be.
#
#  Claude has never run this and must never run it. If a session offers to,
#  the answer is no.
#
#  WHY IT MATTERS MORE THAN ANY FEATURE ON THE LIST
#
#  On Android the signing key is the app's permanent identity. Android will
#  only let version 2 replace version 1 if both were signed with the same key.
#
#  Right now app-release.apk is signed with the DEBUG key -- a throwaway that
#  every Flutter developer on earth has an identical copy of. If that APK goes
#  to five people and you later make a real key, their phones REFUSE the
#  update. The only way through is to uninstall, and allowBackup="false" means
#  uninstalling destroys their vault.
#
#  The first thing you would ever do to your first five users is delete their
#  journals. Make the key before anybody installs anything.
#
#  AND THE PART THAT CANNOT BE UNDONE
#
#  Lose this keystore and you can never update your own app again. Not with a
#  backup of the source, not with Google's help, not ever. The only fix is a
#  new listing under a new name and asking everybody to reinstall.
#
#  So: THREE COPIES, IN THREE PLACES. The script says this again at the end
#  because it is the single most important sentence in the file.
#
#  Usage, from the repo root:
#      powershell -ExecutionPolicy Bypass -File tool\make_release_key.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Lamplight -- release signing key" -ForegroundColor Cyan
Write-Host "================================"
Write-Host ""

# -- Where things go, and why they are not in the same folder -----------------
#
# key.properties lives in android/, because that is `rootProject` for the
# Gradle build and is where build.gradle.kts reads it from.
#
# The keystore lives in android/app/. This looks inconsistent and is not:
# `storeFile = file(...)` is evaluated inside the :app project, so Gradle
# resolves it relative to android/app/ -- NOT relative to key.properties. A
# bare filename sitting in android/ would fail at signing time with a path
# error that explains none of that, on the day of a release.
#
# Both are covered by .gitignore (`*.jks`, `key.properties`) -- CLAUDE.md rule
# 9 -- because a signing key in public git history is permanent.

$repo       = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $repo "app\android"
$appDir     = Join-Path $androidDir "app"
$keystore   = Join-Path $appDir "lamplight-release.jks"
$props      = Join-Path $androidDir "key.properties"

if (-not (Test-Path $appDir)) {
    Write-Host "Cannot find $appDir." -ForegroundColor Red
    Write-Host "Run this from the Lamplight repo: powershell -File tool\make_release_key.ps1"
    exit 1
}

# -- Refuse to overwrite ------------------------------------------------------
#
# Not a convenience check. Overwriting a keystore that has already signed a
# release is the unrecoverable mistake this whole file is about, and it would
# take one absent-minded second.

if (Test-Path $keystore) {
    Write-Host "A keystore already exists:" -ForegroundColor Yellow
    Write-Host "  $keystore"
    Write-Host ""
    Write-Host "NOT overwriting it. If this key has ever signed a release that"
    Write-Host "anyone installed, replacing it would strand every one of them."
    Write-Host ""
    Write-Host "If you are certain you want a new one, move the old file away"
    Write-Host "by hand first -- do not delete it."
    exit 1
}

# -- Find keytool -------------------------------------------------------------
#
# It ships with the JDK. Flutter bundles one through Android Studio, so the
# usual answer is Android Studio's jbr -- but the order below tries the
# environment first in case a real JDK is installed.

$candidates = @()
if ($env:JAVA_HOME)    { $candidates += (Join-Path $env:JAVA_HOME "bin\keytool.exe") }
$candidates += @(
    "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jre\bin\keytool.exe",
    "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\keytool.exe"
)

$keytool = $null
foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) { $keytool = $c; break }
}
if (-not $keytool) {
    $found = Get-Command keytool -ErrorAction SilentlyContinue
    if ($found) { $keytool = $found.Source }
}

if (-not $keytool) {
    Write-Host "Could not find keytool." -ForegroundColor Red
    Write-Host ""
    Write-Host "It comes with the Java that Android Studio installs. Either:"
    Write-Host "  - install Android Studio, or"
    Write-Host "  - set JAVA_HOME to a JDK and run this again."
    exit 1
}

Write-Host "Using keytool at:"
Write-Host "  $keytool"
Write-Host ""

# -- The password -------------------------------------------------------------
#
# Read here, by you, into a PowerShell SecureString, and never printed. Claude
# never sees it and it is not in the shell history. It goes into
# key.properties, which is gitignored, and into the keystore itself.

Write-Host "Choose a password for the keystore." -ForegroundColor Cyan
Write-Host "Write it down somewhere permanent BEFORE you type it. If you lose"
Write-Host "it you lose the ability to update Lamplight, forever."
Write-Host ""

$p1 = Read-Host -AsSecureString "Password"
$p2 = Read-Host -AsSecureString "Password again"

$plain1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($p1))
$plain2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($p2))

if ($plain1 -ne $plain2) {
    Write-Host "Those did not match. Nothing was created." -ForegroundColor Red
    exit 1
}
# Java reads .properties as Latin-1. A password with an emoji or a non-Latin
# character would be written as UTF-8 and read back as something else, so the
# keystore would be created with one password and Gradle would try to open it
# with another -- a mismatch that only shows up at the next release, long after
# anybody remembers typing it.
if ($plain1 -match '[^ -~]') {
    Write-Host "Use only ordinary keyboard characters -- letters, digits," -ForegroundColor Red
    Write-Host "spaces and punctuation. Accents and emoji are stored one way" -ForegroundColor Red
    Write-Host "and read back another, and the mismatch would not show up" -ForegroundColor Red
    Write-Host "until your next release. Nothing was created." -ForegroundColor Red
    exit 1
}
if ($plain1.Length -lt 12) {
    # Not arbitrary. This password guards the identity of the app for its whole
    # life, it is typed roughly twice a year, and there is no rate limit on an
    # offline file -- so length is the only defence it has.
    Write-Host "Use at least 12 characters. Nothing was created." -ForegroundColor Red
    exit 1
}

# -- Make it ------------------------------------------------------------------
#
# RSA 4096 and 10000 days (about 27 years). Google Play requires a key valid
# past 2033 and refuses anything shorter, and a key that expires is a listing
# that cannot be updated.

Write-Host ""
Write-Host "Creating the keystore..." -ForegroundColor Cyan

& $keytool -genkeypair `
    -v `
    -keystore  $keystore `
    -storetype PKCS12 `
    -keyalg    RSA `
    -keysize   4096 `
    -validity  10000 `
    -alias     lamplight `
    -storepass $plain1 `
    -keypass   $plain1 `
    -dname     "CN=Lamplight, OU=Lamplight, O=Lamplight, L=, S=, C=IN"

if ($LASTEXITCODE -ne 0) {
    Write-Host "keytool failed. Nothing usable was created." -ForegroundColor Red
    exit 1
}

# -- Tell Gradle about it -----------------------------------------------------
#
# WRITTEN WITHOUT A BYTE-ORDER MARK, AND THAT IS NOT A DETAIL.
#
# `Set-Content -Encoding utf8` on Windows PowerShell 5.1 prepends three bytes
# (EF BB BF) to the file. Java reads a .properties file as Latin-1, so those
# bytes become visible characters glued to the FIRST key -- Gradle then looks
# for `storeFile`, finds a key called `<BOM>storeFile`, and the release build
# fails with a null cast that says nothing about encodings.
#
# This happened. It cost a build and it would have happened to every person who
# ever ran this script. WriteAllText with a UTF8Encoding constructed as
# `$false` emits no BOM.

$content = @"
storeFile=lamplight-release.jks
storePassword=$plain1
keyAlias=lamplight
keyPassword=$plain1
"@

[System.IO.File]::WriteAllText(
    $props,
    $content,
    (New-Object System.Text.UTF8Encoding $false)
)

# The password is out of memory as far as this process is concerned. It is not
# real protection -- it was on the heap a moment ago -- but leaving it in a
# variable for the rest of the session is worse for no benefit.
$plain1 = $null
$plain2 = $null

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host ""
Write-Host "  keystore : $keystore"
Write-Host "  gradle   : $props"
Write-Host ""

# -- The part people skip -----------------------------------------------------

Write-Host "NOW DO THIS, TODAY:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Copy lamplight-release.jks to THREE separate places."
Write-Host "     A USB stick, a cloud drive, and somewhere physical."
Write-Host "     Not three folders on this laptop. Three places."
Write-Host ""
Write-Host "  2. Write the password down somewhere that is not this laptop."
Write-Host ""
Write-Host "  3. Check both files are ignored by git:"
Write-Host "       git status --short app/android/"
Write-Host "     It must show NOTHING. If either file appears, stop and fix"
Write-Host "     .gitignore before your next commit. A key in public git"
Write-Host "     history is permanent."
Write-Host ""
Write-Host "  4. Build and confirm the warning is gone:"
Write-Host "       flutter build apk --release"
Write-Host "     The 'signing with the DEBUG key' line should not appear."
Write-Host ""
Write-Host "Losing this file means never being able to update Lamplight again."
Write-Host ""
