# ─────────────────────────────────────────────────────────────────────────────
#  What R8 is allowed to touch, and what it must not.
#
#  Everything in this app is renamed and inlined by default. This file is the
#  short list of exceptions — the places where something outside the Java type
#  system reaches in by name, and where renaming would therefore break the app
#  at runtime with an error that says nothing useful.
#
#  Every rule below names WHY it exists. A `-keep` with no reason is a rule
#  nobody will ever dare delete, and a proguard file full of those is a
#  proguard file that has stopped doing its job.
# ─────────────────────────────────────────────────────────────────────────────

# ── Flutter's own engine, and the seven rules that used to be here ──────────
#
# **Removed 23 September 2026, and this is the reasoning, because the deleted
# rules looked like the careful option.**
#
# They were:
#
#     -keep class io.flutter.app.** { *; }
#     -keep class io.flutter.plugin.** { *; }
#     -keep class io.flutter.embedding.** { *; }
#     -keep class io.flutter.util.** { *; }
#     -keep class io.flutter.view.** { *; }
#     -keep class io.flutter.** { *; }          <- subsumes all of the above
#     -keep class io.flutter.plugins.** { *; }
#
# with the note *"Flutter ships these rules itself, but stating them here means
# a change to the plugin's defaults cannot quietly break a release build."*
# That sentence is careful and its conclusion was wrong, in a way worth keeping
# a record of: **it asserted what Flutter's rules are without reading them.**
#
# They are in `packages/flutter_tools/gradle/flutter_proguard_rules.pro`, the
# Flutter Gradle plugin adds them to every release build automatically
# (`FlutterPlugin.kt`, beside `proguard-android-optimize.txt` and this file),
# and in full they are two `-dontwarn`s and this:
#
#     -if class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
#     -keep,allowshrinking,allowobfuscation class <1>
#
# **`allowshrinking, allowobfuscation`.** Flutter does not ask for its embedding
# to be kept whole; it asks for plugin implementations to survive by *identity*
# while still being renamed and trimmed. The blanket rules above were not
# restating Flutter's defaults — they were overriding them with something far
# broader, and `{ *; }` keeps every member of every class in the engine's Java
# embedding under its original name.
#
# The cost was on the Play Console, which reported the DEX at **46% optimized,
# 48% obfuscated, 47% shrunk** — roughly half the bytecode in the app untouched,
# and the half an attacker with the APK would read first.
#
# Nothing replaces them. Flutter's own rules are applied automatically and are
# correct; `MainActivity` and the two receivers are kept below because the
# *manifest* names them as strings, which is a real reference R8 cannot see and
# is the actual version of the problem the deleted rules imagined.

# ── Play Core, which this app deliberately does not have ─────────────────────
#
# Flutter's engine carries `PlayStoreDeferredComponentManager` — the machinery
# for downloading parts of an app on demand from the Play Store. It is
# unreachable here: there are no deferred components, and an app with no
# INTERNET permission could not download one if there were.
#
# R8 still sees the references and stops the build over classes that are not on
# the classpath. `-dontwarn` rather than adding the Play Core library, because
# adding it would pull a Google service dependency into an app whose entire
# claim is that it talks to nobody. The dead code is removed either way.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# ── Our own platform boundary ────────────────────────────────────────────────
#
# The Activity is named as a string in AndroidManifest.xml, and the two
# receivers are named there too. The manifest is not compiled, so R8 cannot see
# the reference — rename the class and Android throws ClassNotFoundException at
# the moment somebody taps the icon.
-keep class com.probablypiyush.lamplight.MainActivity { *; }
-keep class com.probablypiyush.lamplight.ReminderReceiver { *; }
-keep class com.probablypiyush.lamplight.BootReceiver { *; }

# ── MediaDataSource, and why it has to survive ───────────────────────────────
#
# Both players hand Android an anonymous subclass of MediaDataSource and the
# platform calls `readAt` on it from a binder thread, by signature, through the
# framework's own code. R8 sees a class nothing in our code calls and is
# entirely right to want to strip it. Losing it means audio and video fail with
# a native error rather than a Dart one, which is the worst kind to debug.
-keep class * extends android.media.MediaDataSource { *; }

# ── androidx.biometric ───────────────────────────────────────────────────────
#
# Reaches the Keystore through reflection on some vendor forks, and a stripped
# member there means the fingerprint stops working on one manufacturer's phones
# and nowhere else — a bug that would never reproduce on the development device.
# `androidx.biometric` stays whole. It is small, the failure it guards against
# is a stripped member on one manufacturer's fork — a bug that by definition
# will not reproduce on the development phone — and the vault's second way in
# is not the place to be greedy for a percentage.
-keep class androidx.biometric.** { *; }

# The three that used to follow it are gone: `android.security.keystore`,
# `javax.crypto` and `java.security` are **platform** classes, provided by
# android.jar at runtime and never present in this app's DEX. Keeping them
# protected nothing, because there was nothing there to strip.

# ── sqlite3 / SQLCipher, and libsodium ───────────────────────────────────────
#
# Both are native libraries reached through FFI. The Dart side looks up symbols
# by name in the shared object, so **there is no Java reference here at all** —
# which is also why the two `-keep`s that used to be here did nothing. They
# named packages this app does not ship: `sqlite3` and `sodium` are `.so` files
# read by `dart:ffi`, not Java libraries with a shim. Kept as a `-dontwarn` and
# a note, so the next person does not add the keeps back looking for safety
# they never provided.
-dontwarn org.sqlite.**

# ── What NOT to keep, stated so nobody adds it "to be safe" ──────────────────
#
# There is no `-keepattributes SourceFile,LineNumberTable` here, on purpose.
# Keeping them puts the original filenames and line numbers of every crash into
# the shipped binary, which is most of the map an attacker would otherwise have
# to build. This app has no crash reporter and sends nothing anywhere, so there
# is nobody on the other end who would benefit from a readable stack trace —
# only somebody holding the APK.
#
# `--split-debug-info` on the Dart side does the same job the right way round:
# the symbols exist, in a file on the developer's machine, and not in the thing
# that ships.

# Renaming and repackaging everything that is left into the default package
# makes the decompiled output a flat list of single-letter classes with no
# hierarchy to read.
-repackageclasses ''
-allowaccessmodification

# Strip every log call from the release binary.
#
# Not for size. `Log.d(TAG, "unlocking with " + …)` is exactly the line that
# somebody adds while debugging and forgets, and logcat is readable by adb from
# any machine the phone is plugged into. Removing the calls at build time means
# a forgotten one cannot ship. CLAUDE.md rule 2's spirit — nothing readable
# leaves the vault — includes the log.
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
    public static *** wtf(...);
}
