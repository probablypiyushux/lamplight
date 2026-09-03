# Security policy

Lamplight is a journal. The worst outcome this project can produce is not a crash — it is
somebody's private writing becoming readable by someone else. Security reports are
therefore the most valuable thing you can send.

## Reporting a vulnerability

**Please report privately first**, through
[GitHub's private advisory form](https://github.com/probablypiyushux/lamplight/security/advisories/new).
That reaches the maintainer without the report becoming public while it is unfixed.

If that form is unavailable to you, open an issue titled `Security` with **no technical
detail in it**, and you will be asked for a private channel.

Expect an acknowledgement within a few days.

**Never include anything from your own journal in a report** — not an entry, not a
screenshot of one, not a `.vault` file. If a bug can only be shown with real content, say
so and it will be reproduced from synthetic data instead. A public bug report that leaks
the reporter's diary would be a worse outcome than the bug.

## In scope

Anything that would let someone read, alter or destroy a vault they do not own:

- Recovering plaintext from the device after any capture or import path
- Weaknesses in the key hierarchy, the `.vault` format, or the passcode and
  recovery-phrase derivations — see
  [`02-security/SECURITY-ARCHITECTURE.md`](02-security/SECURITY-ARCHITECTURE.md)
- Anything that causes the shipped app to open a network connection
- Bypassing the lock screen, the idle lock, or `FLAG_SECURE`
- A dependency that reaches the network, collects analytics, or merges an `INTERNET`
  permission through its own manifest

## Known and accepted

Documented decisions rather than oversights.
[`02-security/THREAT-MODEL.md`](02-security/THREAT-MODEL.md) explains each in full. Reports
about them are welcome but will not be treated as new findings.

- **A compromised device defeats this app.** Root, a malicious keyboard, or a screen
  recorder holding accessibility permission all sit above anything an app can defend
  against.
- **A forgotten passcode and a lost recovery phrase mean the journal is gone.** There is no
  reset, because there is nobody to reset it.
- **The `.vault` footer digest is an unkeyed BLAKE2b**, so deliberate truncation is caught
  by gzip's trailer rather than by the crypto. Recorded in
  [`02-security/RED-TEAM-2026-08-28.md`](02-security/RED-TEAM-2026-08-28.md); both fixes
  change the file format, so it is queued for a v3 reader rather than patched in place.
- **The debug and profile builds declare `INTERNET`.** Flutter requires it for hot reload
  and for on-device integration tests, including the plaintext-leak scan. Those variants
  are never distributed, and `tool/verify_no_internet.sh` reads a built *release* APK
  precisely so the rule is enforced mechanically rather than by care.
- **"Open with" writes one decrypted file** into a private FileProvider directory so
  another app can read it — a one-time grant, revoked and deleted the moment Lamplight
  returns to the foreground. It is the single exception to the no-plaintext-on-disk rule,
  it is deliberate, and a test searches the disk afterwards for the file's *content*
  rather than its name.

## Verifying a release yourself

Nothing here has to be taken on trust:

```bash
aapt2 dump permissions app-release.apk     # no INTERNET
tool/verify_no_internet.sh                 # the same, against the built artefact
tool/verify_no_sockets.sh                  # every symbol each .so imports
apksigner verify --print-certs app-release.apk
```

The signing fingerprint to compare against is published in
[`05-shipping/FINGERPRINT.md`](05-shipping/FINGERPRINT.md).

## Supported versions

Pre-1.0. Only the most recent release receives fixes.
