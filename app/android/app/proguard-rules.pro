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

# ── Flutter's own engine ─────────────────────────────────────────────────────
#
# The engine looks up embedding classes reflectively from C++. Flutter ships
# these rules itself, but stating them here means a change to the plugin's
# defaults cannot quietly break a release build.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

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
-keep class androidx.biometric.** { *; }
-keep class android.security.keystore.** { *; }
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# ── sqlite3 / SQLCipher, and libsodium ───────────────────────────────────────
#
# Both are native libraries reached through FFI. The Dart side looks up symbols
# by name in the shared object, so nothing here is a Java reference R8 can
# follow — but any Java shim they carry must stay whole.
-keep class org.sqlite.** { *; }
-keep class com.sodium.** { *; }
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
