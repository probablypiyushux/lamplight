# The signing fingerprint

**Every official Lamplight build is signed with this certificate:**

```
SHA-256
CC:F5:D5:83:16:F3:66:3B:21:2D:0A:5D:D5:67:52:67:4B:7C:2D:F0:41:A2:F3:58:63:D8:A5:D1:EB:95:D1:7B
```

```
SHA-1
8E:81:66:70:6D:24:B6:D9:60:25:3D:86:ED:5C:37:55:84:19:F7:00
```

```
Certificate
CN=Lamplight, OU=Lamplight, O=Lamplight, C=IN
```

*First used 25 August 2026. Recorded from the first release build signed with the
real key, verified with `apksigner verify --print-certs`.*

---

## What this is for

An Android app can only be replaced by an update carrying the **same** signature.
That is how your phone knows a "Lamplight update" really came from the person who
wrote Lamplight and not from somebody who rebuilt it with an extra feature in it.

This file publishes that signature so you can check for yourself.

## How to check the copy on your phone

**Settings → About → "Check this is the real Lamplight"**

It shows the fingerprint of the build you are actually running. Compare it with the
SHA-256 above. If they match, the app on your phone was built and signed by the
holder of the Lamplight key.

If they **don't** match, that build did not come from here. It may be harmless — a
fork, or somebody building from source for themselves, which the licence explicitly
allows — but it is not the app this repository publishes, and you should not trust
it with your notes on the strength of anything written here.

## How to check an APK before installing it

```bash
apksigner verify --print-certs app-release.apk
```

`apksigner` ships with the Android SDK build-tools.

---

## Why the app does not check this itself

It would be easy to bake the expected value into the app and have it verify itself
on launch. **That would be worse than doing nothing.**

An attacker who can rebuild and resign the app can also change the number it
compares against. A self-check would pass on a tampered build while looking
reassuring — the worst combination available. The comparison only means anything
when it is made by a person, against a number published somewhere the app cannot
reach.

So the app shows you the fingerprint and nothing more. The checking is yours.

This is `PLAN.md` §11 test 3 — *could a stranger verify the claim themselves in
thirty seconds?* — applied to identity rather than to permissions.
`tool/verify_no_internet.sh` is the same test applied to the network claim.

---

## If this ever changes

It should not. The key is valid until roughly 2053 and cannot be rotated without
orphaning every install that exists — Android would refuse the update, and
`allowBackup="false"` means the only way through is an uninstall that destroys the
vault.

**If a future release is ever signed with a different key, that is not a routine
change and must not be presented as one.** It would mean the original key was lost
or compromised, everyone would have to uninstall and restore from a `.vault` backup,
and both the reason and the new fingerprint belong in the release notes in plain
words.

The old fingerprint stays in this file if that day comes. A published fingerprint
that quietly disappears is indistinguishable from one being covered up.
