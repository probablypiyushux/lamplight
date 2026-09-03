#!/usr/bin/env bash
#
# Proves that a built Lamplight release artifact cannot reach the network.
#
# WHY THIS IS A SCRIPT AND NOT A HABIT
#
#   02-security/THREAT-MODEL.md adversary #4 is us, the developer. The defence
#   offered there is not a promise to behave. It is that a release build has no
#   way to open a socket, and that any stranger holding the APK can confirm it
#   in thirty seconds. A claim like that is only worth something if it cannot
#   quietly stop being true.
#
#   It can stop being true without anyone editing a file we review. Android
#   merges the manifest of every dependency into the final one. A package added
#   three phases from now — or a transitive dependency of that package — can
#   introduce INTERNET on its own, and it will not appear in a diff of our
#   source. So this reads the permissions out of the BUILT ARTIFACT. What ships
#   is what gets checked.
#
# WHAT COUNTS AS A FAILURE
#
#   Any permission in a namespace we do not own. In particular INTERNET, which
#   is called out separately because it is the one the whole architecture rests on.
#
#   Permissions namespaced under our own applicationId are allowed, but only if
#   they are protectionLevel="signature" — meaning only an app signed with our
#   key can hold them, so no other app on the device can obtain one. AndroidX
#   declares exactly one of these (DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION) and
#   uses it to keep our internal broadcast receivers unexported. That is a
#   hardening measure, not an access grant. Anything else is reported in full so
#   a human decides rather than a regex.
#
# Usage:  tool/verify_no_internet.sh [path-to-apk]
# Exit:   0 clean, 1 otherwise.

set -uo pipefail

APK="${1:-app/build/app/outputs/flutter-apk/app-release.apk}"

if [ ! -f "$APK" ]; then
  echo "FAIL: no artifact at $APK"
  echo "      build one first:  cd app && flutter build apk --release"
  exit 1
fi

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/AppData/Local/Android/Sdk}}"
AAPT="$(find "$SDK/build-tools" -maxdepth 2 -name 'aapt2*' -type f 2>/dev/null | sort -r | head -1)"
if [ -z "$AAPT" ]; then
  echo "FAIL: aapt2 not found under $SDK/build-tools. Set ANDROID_HOME."
  exit 1
fi

PKG="$("$AAPT" dump packagename "$APK" 2>/dev/null | tr -d '\r')"
echo "artifact : $APK"
echo "package  : $PKG"
echo "size     : $(( $(wc -c < "$APK") / 1024 )) KB"
echo

PERMS="$("$AAPT" dump permissions "$APK" 2>/dev/null | tr -d '\r' \
         | grep -E "^uses-permission" | sed "s/.*name='//; s/'.*//")"

FAILED=0

# --- the one that matters, checked by name and checked loudly -----------------
if echo "$PERMS" | grep -qx "android.permission.INTERNET"; then
  echo "FAIL: android.permission.INTERNET is present in the release artifact."
  echo "      This breaks non-negotiable rule 1 in CLAUDE.md and invalidates the"
  echo "      central claim of THREAT-MODEL.md adversary #4. Do not ship this."
  FAILED=1
fi

# --- the permissions we have deliberately decided to ship ----------------------
#
# This list is the point of the script. It used to be empty, and the script's
# rule was "any permission at all is a failure" — which was correct while the
# app had none, and stopped being correct the moment voice notes shipped.
#
# The temptation at that moment is to relax the check. Don't. The value here is
# not that the number is zero, it is that the number is **decided**: every entry
# below had to be typed by a person who knew what it was for, and anything that
# appears without being typed here fails the build.
#
# That is the case this actually defends against. Android merges the manifest of
# every dependency into the final one, so a package added three phases from now
# — or a transitive dependency of that package — can introduce a permission on
# its own, and it will not show up in a diff of anything we wrote.
#
# To add one: put it here WITH the reason, and update the manifest comment and
# 02-security/THREAT-MODEL.md at the same time. Three places, on purpose.
ALLOWED_PERMS=$(cat <<'EOF'
android.permission.RECORD_AUDIO
android.permission.USE_BIOMETRIC
android.permission.USE_FINGERPRINT
android.permission.POST_NOTIFICATIONS
android.permission.RECEIVE_BOOT_COMPLETED
EOF
)
# Why each one is here:
#   USE_BIOMETRIC / USE_FINGERPRINT
#                 merged in by androidx.biometric. protectionLevel="normal":
#                 granted at install, no runtime prompt, and they do not read a
#                 fingerprint — they only permit showing the system dialog. The
#                 real protection is the keystore key being bound to
#                 BIOMETRIC_STRONG. They appeared here because this script
#                 failed the build when they turned up unannounced, which is
#                 exactly the case it exists for.
#
#   RECORD_AUDIO  voice notes. Requested the first time someone taps record, not
#                 at launch (UX-FLOWS.md flow 1). Paired with the absence of
#                 INTERNET above: a microphone on an app that provably cannot
#                 open a socket is a microphone that records to your own disk.
#
#   POST_NOTIFICATIONS / RECEIVE_BOOT_COMPLETED
#                 the optional daily reminder, off by default. The reminder runs
#                 in a BroadcastReceiver with no keys, no database and no Flutter
#                 engine, so it is *incapable* of saying anything about what is
#                 in the vault — see Reminders.kt and the manifest comment above
#                 both of them. BOOT_COMPLETED is what puts the alarm back after
#                 a restart; without it the reminder silently stops working
#                 forever the first time the phone reboots.
#
#                 **Added to this list on 22 August 2026, and that is a finding
#                 in itself.** They had been in the manifest since the reminder
#                 shipped and were never added here, so this script had been
#                 failing every time it ran — which is to say it had stopped
#                 being a check and started being a chore. Exactly the pattern
#                 the 22 August audit found in the test suite: a gate that always
#                 says no cannot say no to the thing that matters. The rule below
#                 is the fix: three places, on purpose, and none of them optional.
#
# Deliberately NOT here, and each absence is load-bearing:
#   CAMERA              the camera app takes the photo; we hand it a FileProvider URI
#   READ_MEDIA_IMAGES   gallery import goes through SAF — the user picking a file IS the grant
#   READ/WRITE_EXTERNAL backups and imports are SAF too, for the same reason

FOREIGN="$(echo "$PERMS" | grep -v "^${PKG}\." | grep -v '^$' || true)"
UNEXPECTED=""
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if ! echo "$ALLOWED_PERMS" | grep -qx "$p"; then
    UNEXPECTED="${UNEXPECTED}${p}"$'\n'
  fi
done <<< "$FOREIGN"

if [ -n "${UNEXPECTED//[$'\n\t ']/}" ]; then
  echo "FAIL: permissions in the artifact that nobody decided to ship:"
  echo "$UNEXPECTED" | grep -v '^$' | sed 's/^/        /'
  echo
  echo "      Either a dependency merged these in, or someone added them without"
  echo "      updating ALLOWED_PERMS in this script. Trace the source in:"
  echo "        app/build/app/outputs/logs/manifest-merger-release-report.txt"
  FAILED=1
fi

# Report the intended ones, so a passing run still shows what ships.
EXPECTED_PRESENT="$(echo "$FOREIGN" | grep -x -F -f <(echo "$ALLOWED_PERMS") || true)"
if [ -n "$EXPECTED_PRESENT" ]; then
  echo "declared on purpose:"
  echo "$EXPECTED_PRESENT" | sed 's/^/        /'
  echo
fi

# --- our own namespace: allowed, but must be signature-level ------------------
OWN="$(echo "$PERMS" | grep "^${PKG}\." || true)"
if [ -n "$OWN" ]; then
  XML="$("$AAPT" dump xmltree --file AndroidManifest.xml "$APK" 2>/dev/null | tr -d '\r')"
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    # Find the <permission> declaration for this name and read the level that
    # follows it. 0x2 is the numeric encoding of protectionLevel="signature".
    LEVEL="$(echo "$XML" | grep -A6 "E: permission" | grep -A3 "\"$p\"" \
             | grep 'protectionLevel' | head -1 | sed 's/.*=//' | tr -d ' ')"
    LEVELNUM=$(( LEVEL )) 2>/dev/null || LEVELNUM=-1
    # PROTECTION_SIGNATURE = 0x2. aapt2 prints it zero-padded, so compare numbers.
    if [ "$LEVELNUM" -eq 2 ]; then
      echo "ok   : $p"
      echo "       self-namespaced, protectionLevel=signature — only an app signed"
      echo "       with our key can hold it, so no other app can obtain it."
    else
      echo "FAIL : $p"
      echo "       self-namespaced but protectionLevel is '$LEVEL', not signature."
      FAILED=1
    fi
  done <<< "$OWN"
  echo
fi

if [ "$FAILED" -eq 0 ]; then
  echo "PASS: no network permission, and nothing any other app can hold."
  echo "      Confirm it independently:"
  echo "        aapt2 dump permissions $(basename "$APK")"
  exit 0
fi
exit 1
