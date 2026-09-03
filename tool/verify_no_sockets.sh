#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
#  Proves no native library in the APK can open a socket.
#
#  ── WHY THIS EXISTS BESIDE verify_no_internet.sh ─────────────────────────────
#
#  `verify_no_internet.sh` reads the permissions out of the built APK, and it is
#  the strongest single claim this project makes. It has one blind spot, and
#  ISSUE 15 walked straight into it: **a native library does not need a Java
#  permission to be worrying.**
#
#  Android does enforce INTERNET at the kernel level, so a `socket()` call from
#  C would in fact fail — that is real and it is the backstop. But "the operating
#  system would have stopped it" is a much weaker sentence than "there is no code
#  in there that tries", and this app's whole pitch is that you can check things
#  yourself rather than take somebody's word.
#
#  A shared library declares every function it imports from outside itself. If
#  `socket`, `connect` or `getaddrinfo` are not in that list, the code inside
#  cannot call them — not "does not", cannot. That is the whole test.
#
#  ── WHAT CHANGED ON 28 AUGUST 2026, AND WHY IT IS STRONGER NOW ───────────────
#
#  This used to check exactly one file: `liblamplight_whisper.so`, the vendored
#  whisper.cpp. Whisper was removed that day, and a gate whose only subject no
#  longer exists is a gate that reports "nothing to check" for ever — which under
#  LAMPLIGHT_STRICT is a failed build, and without it is a green tick that means
#  nothing at all.
#
#  So it is an **inventory** now. Every `.so` in the APK is listed and matched
#  against the set this app is known to ship. Anything outside that set is new
#  native code, and new native code gets its imports checked.
#
#  That is a better gate than the one it replaces in two ways. It notices native
#  code arriving by any route — a dependency that starts bundling a library, not
#  just something we vendored on purpose. And it has something to say when the
#  project has no native code of its own, which is the state it is in today.
#
#  The six expected libraries are Flutter's engine and Dart AOT output, the NDK's
#  C++ runtime, libsodium and SQLCipher. They are not audited here: they are
#  large third-party binaries whose imports are their own business, and
#  `libflutter.so` legitimately carries socket symbols because the engine has a
#  networking stack compiled in that this app never reaches — the permission is
#  what stops that, which is `verify_no_internet.sh`'s job.
#
#  Usage:
#      bash tool/verify_no_sockets.sh app/build/app/outputs/flutter-apk/app-release.apk
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

APK="${1:-app/build/app/outputs/flutter-apk/app-release.apk}"

# ── The libraries this app is known to ship ─────────────────────────────────
#
# Basenames, so the check is the same for every ABI slice. Adding to this list
# is how you declare a new native dependency, and it should never be done
# without the rule-4 justification in `04-technical/TECH-STACK.md`.
EXPECTED='libapp.so libc++_shared.so libdartjni.so libflutter.so libsodium.so libsqlcipher.so'


if [ ! -f "$APK" ]; then
  echo "FAIL: no such artifact: $APK" >&2
  exit 2
fi

# The NDK's nm. Found rather than assumed, because the version in the path moves
# with every SDK update and a hard-coded one fails a year from now with a
# message about a missing file rather than about a missing NDK.
# ── STRICT MODE, AND WHY A GATE NEEDS ONE ────────────────────────────────────
#
# Both of the "cannot check" paths below used to `exit 0`. On a laptop with no
# NDK that is right — the answer is genuinely unknown and refusing would be
# noise. **In CI it is the worst possible outcome**, because a green tick then
# means "nothing was checked" while looking exactly like "nothing was found".
#
# So: set LAMPLIGHT_STRICT=1 — as `.github/workflows/verify.yml` does — and
# every unknown becomes a failure. A release gate that can silently pass is not
# a gate.
STRICT="${LAMPLIGHT_STRICT:-0}"

cannot_check() {
  if [ "$STRICT" = "1" ]; then
    echo "FAIL: $1" >&2
    echo "      (LAMPLIGHT_STRICT=1: an unknown is a failure, because a tick" >&2
    echo "       that means 'not checked' is worse than a red build.)" >&2
    exit 1
  fi
  echo "SKIP: $1" >&2
  exit 0
}

NM="$(find "${ANDROID_HOME:-$HOME/AppData/Local/Android/Sdk}/ndk" \
        -name 'llvm-nm*' -type f 2>/dev/null | head -1)"
if [ -z "$NM" ]; then
  NM="$(command -v llvm-nm || command -v nm || true)"
fi
if [ -z "$NM" ]; then
  cannot_check "no llvm-nm found. Install the NDK, or run this where one is."
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "artifact : $APK"

ALL_SO="$(unzip -Z1 "$APK" 'lib/*/*.so' 2>/dev/null || true)"
if [ -z "$ALL_SO" ]; then
  cannot_check "no native libraries at all in this APK, which cannot be right —
      Flutter always ships its engine. The artifact is probably not a real
      build."
fi

TOTAL="$(printf '%s\n' "$ALL_SO" | grep -c . || true)"
echo "native   : $TOTAL library slices"

# Anything whose basename is not in EXPECTED is native code that arrived since
# this gate was written, whether we vendored it or a dependency brought it.
UNKNOWN=""
for entry in $ALL_SO; do
  base="${entry##*/}"
  case " $EXPECTED " in
    *" $base "*) ;;
    *) UNKNOWN="$UNKNOWN $entry" ;;
  esac
done

if [ -z "$UNKNOWN" ]; then
  echo "unknown  : none — every library is one of:"
  for e in $EXPECTED; do echo "             $e"; done
  echo ""
  echo "PASS: this app ships no native code of its own, so there is none that"
  echo "      could open a socket. The libraries above are Flutter, Dart, the"
  echo "      NDK C++ runtime, libsodium and SQLCipher; the INTERNET permission"
  echo "      is what constrains those, and verify_no_internet.sh checks it."
  echo "      Confirm this list independently:"
  echo "        unzip -Z1 $APK 'lib/*/*.so'"
  exit 0
fi

# Something new. Check what it imports.
echo "unknown  :$UNKNOWN"
echo ""

# Everything a socket needs, plus the libraries that would wrap one. A library
# that calls none of these cannot reach a network by any route.
BANNED='socket|connect|bind|listen|accept|sendto|recvfrom|sendmsg|recvmsg|getaddrinfo|gethostby|inet_|res_query|SSL_|curl_|__android_res'

FAILED=0
for entry in $UNKNOWN; do
  if ! unzip -o -q "$APK" "$entry" -d "$WORK" 2>/dev/null; then
    cannot_check "could not extract $entry from the APK."
  fi
  SO="$WORK/$entry"
  IMPORTS="$("$NM" --undefined-only --dynamic "$SO" 2>/dev/null || true)"
  COUNT="$(printf '%s\n' "$IMPORTS" | grep -c . || true)"
  if [ "$COUNT" = "0" ]; then
    cannot_check "$NM read no symbols from $entry. Wrong tool for this
      architecture, or a stripped library — either way nothing was checked."
  fi
  HITS="$(printf '%s\n' "$IMPORTS" | grep -Ei "$BANNED" || true)"
  echo "  $entry: $COUNT imported symbols"
  if [ -n "$HITS" ]; then
    echo "" >&2
    echo "FAIL: $entry imports symbols that can reach a network:" >&2
    printf '%s\n' "$HITS" | sed 's/^/        /' >&2
    FAILED=1
  fi
done

if [ "$FAILED" = "1" ]; then
  echo "" >&2
  echo "      A native library that can open a socket is not constrained by the" >&2
  echo "      manifest in any way a reader can check. Either remove it, or" >&2
  echo "      document it in 04-technical/TECH-STACK.md and add it to EXPECTED" >&2
  echo "      in this script with the reasoning." >&2
  exit 1
fi

echo ""
echo "PASS: nothing in the native libraries can open a socket."
echo "      Confirm it independently:"
echo "        unzip -Z1 $APK 'lib/*/*.so'"
exit 0
