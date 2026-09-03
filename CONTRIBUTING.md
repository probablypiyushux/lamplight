# Contributing

Thank you for looking. A few things are worth knowing before you spend time on a change,
because this project refuses some things on purpose.

## The rules that are not up for negotiation

These are not preferences. A change that breaks one is a bug even if the app still runs,
and it will be declined however good the rest of it is.

1. **No `INTERNET` permission in the shipped manifest.** Not for a small feature, not
   behind a flag. Its absence is verifiable by anyone holding the APK and is the project's
   strongest claim. The debug and profile variants declare it because Flutter's tooling
   requires it; those are never distributed, and `tool/verify_no_internet.sh` reads a built
   *release* APK so the rule is enforced mechanically rather than by care.
2. **No plaintext user content on disk. Ever.** No temp files, caches, thumbnails, logs or
   crash dumps. Every import path scrubs its temporary file, and there is a test proving
   it. There is exactly one documented exception ("Open with"): one file at a time, in a
   private directory, revoked the moment the app returns to the foreground. It does not
   generalise.
3. **No analytics, telemetry, crash reporting, advertising or attribution.** Zero. New
   dependencies are audited for these transitively.
4. **No third-party package without written justification** in
   [`04-technical/TECH-STACK.md`](04-technical/TECH-STACK.md). Every package can read all
   of a user's notes; fewer packages is a security property.
5. **All cryptography goes through `app/lib/core/crypto/`.** Feature code never touches a
   raw key, and that directory stays small enough to audit in an afternoon.
6. **Randomness touching a secret comes only from the OS CSPRNG** — keys, nonces, salts,
   IVs, recovery entropy, and any identifier that must be unguessable. Decoration may use a
   seeded generator; nothing an attacker could benefit from predicting may.
7. **Never claim the app is "unbreakable", "military-grade" or "as secure as Signal"** — in
   code, comments, documentation or store copy. There is a test that enforces the
   vocabulary.

## Before you open a pull request

```bash
cd app
flutter analyze          # must be clean
flutter test             # must be green
```

A change that adds behaviour needs a test that fails without it. That matters more here
than in most projects: several of the worst defects found in this codebase were invisible
to a fully green suite, because the suite checked what was *drawn* rather than what was
delivered. If your change fixes a bug, the most useful thing you can write is the test that
reproduces it — and then check that the test fails when your fix is removed.

Please do not run `flutter run`, `flutter drive` or `flutter test integration_test` against
a device holding a real vault. Their failure paths can uninstall the application, and with
`allowBackup="false"` that deletes the vault permanently.

## Style

Match the surrounding code. Comments here explain **why**, and often record what was tried
and rejected — that is deliberate. A change that removes the reasoning along with the code
is usually a regression waiting to be reintroduced.

Commit messages are prose, not a template. Say what changed, and what was wrong before.

## What is likely to be declined

- Anything that sends data anywhere
- Cloud sync, accounts, or sharing to a service
- A feature needing a permission the app does not already hold
- Widening the plaintext exception
- Dark patterns of any kind — see
  [`08-design/ETHICAL-DESIGN.md`](08-design/ETHICAL-DESIGN.md)

If you want to build any of those, forking is genuinely welcome; the licence permits it.

## Security

Do not open a public issue for a vulnerability. See [`SECURITY.md`](SECURITY.md).
