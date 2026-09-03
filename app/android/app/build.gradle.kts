import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────────────────────
//  SIGNING, AND WHY AN UPDATE MUST NEVER WIPE SOMEBODY'S NOTES
//
//  Android identifies an app by its package name AND its signing key. Two
//  builds signed by different keys are, as far as the operating system is
//  concerned, two different apps — so it refuses to install one over the other,
//  and the only way through is to uninstall first. **Uninstalling deletes
//  /data/data/<package>, which is where the vault lives.**
//
//  That is the whole explanation for "every time you update the app, the data
//  resets". Nothing in the app was ever deleting anything. The debug keystore
//  is generated per machine and differs between the debug and release variants,
//  so every switch between them was silently a fresh install.
//
//  On the Play Store this would be terminal, and it is worth being blunt about
//  why: a release signed with the DEBUG key cannot be updated by a release
//  signed with a real one. If v1 ships debug-signed, every user has to
//  uninstall and lose everything to reach v2 — and for an app whose promise is
//  "we cannot recover your notes", that is not a bad update. That is the end.
//
//  So a real keystore is read from `android/key.properties` when it exists, and
//  the build falls back to debug signing only for local development, loudly.
//  `key.properties` and `*.jks` are in .gitignore from commit one — CLAUDE.md
//  rule 9 — because a signing key in public git history is permanent and cannot
//  be rotated without orphaning every install that ever existed.
//
//  Declared out here rather than inside `android { }` because in the Kotlin DSL
//  `java` inside that block resolves to Gradle's own `java` extension, not the
//  package, and `java.util.Properties` fails to resolve with a message that
//  explains none of that.
// ─────────────────────────────────────────────────────────────────────────────
val releaseKeyFile = rootProject.file("key.properties")
val hasReleaseKey = releaseKeyFile.exists()
val releaseKeyProperties = Properties().apply {
    if (hasReleaseKey) {
        FileInputStream(releaseKeyFile).use { load(it) }
    }
}

android {
    namespace = "com.probablypiyush.lamplight"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // == THE SANDBOX BUILD, AND WHY IT IS A PROPERTY AND NOT A SUFFIX ===
        //
        // 3 September 2026. Testing the destructive half of this app - delete,
        // trash, restore, passcode change, folder delete - cannot be done
        // against a vault holding somebody's real journal. Driving the app
        // over `adb` means tapping coordinates, because Flutter does not
        // expose most rows as clickable nodes, and a tap that misses lands on
        // whatever is underneath. On 3 September one did exactly that and hit
        // a delete.
        //
        // So: `-PlampSandbox=true` builds the same app under a different
        // application id. It installs *alongside* Lamplight, keeps its own
        // vault, and cannot see or touch the real one - Android gives each
        // application id its own private storage, which is the whole point.
        //
        // -- WHY NOT `applicationIdSuffix`, WHICH IS THE OBVIOUS WAY --------
        //
        // Because it has already destroyed a vault in this project. PLAN.md
        // 0 and CLAUDE.md both record it: on 28 August a suffix was added for
        // exactly this reason, and **Flutter's tooling tracks the un-suffixed
        // id**. So `flutter run` installed `...lamplight.debug` and pointed
        // its own cleanup `adb uninstall` at `...lamplight`. With
        // `allowBackup="false"` that deletes /data/data. The safety measure
        // caused the accident.
        //
        // A build-time property avoids that trap rather than re-entering it:
        // the id is different in the artefact, and no Flutter *tooling* is
        // involved. **The sandbox is built with `flutter build apk` and
        // installed with `adb install -r <named file>`, and never with
        // `flutter run`, `flutter drive` or `flutter test integration_test`** -
        // those three are what carry the uninstall, and none of them is used.
        //
        // Absent the property, every byte of this file behaves as it did.
        applicationId = if (project.hasProperty("lampSandbox"))
            "com.probablypiyush.lamplight.sandbox"
        else
            "com.probablypiyush.lamplight"

        // So the two are tellable apart in the launcher and in recents. A
        // tester who cannot see which vault they are in will eventually test
        // the wrong one.
        manifestPlaceholders["appLabel"] =
            if (project.hasProperty("lampSandbox")) "Lamplight Sandbox"
            else "Lamplight"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // ── Why the floor is 26 and not Flutter's default ─────────────────
        //
        // Notification channels, `Notification.Builder(context, channelId)`
        // and `ImageDecoder` all arrive at 26, and every one of them is used
        // unguarded. The alternative is three `Build.VERSION.SDK_INT` branches
        // carrying code for Android 7, which in 2026 is a fraction of a per
        // cent of devices and none of the ones this app will ever run on.
        //
        // `maxOf` rather than a bare 26, so a future Flutter release raising
        // its own floor is not silently lowered by this line.
        minSdk = maxOf(flutter.minSdkVersion, 26)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ── THERE IS NO NATIVE CODE IN THIS PROJECT ANY MORE ───────────────
        //
        // An `externalNativeBuild` block built a vendored whisper.cpp here, and
        // an `abiFilters` line restricted it to `arm64-v8a`. Both are gone with
        // the engine, on 28 August 2026: *"remove this whisper option please
        // ... cause it's trash"*.
        //
        // Worth stating what came back with them, because it is more than a
        // tidy-up. The APK loses a megabyte of compiled ggml and the build
        // loses its CMake step. `CLAUDE.md` rule 4 counts every avoided
        // dependency as a security property, and this was the largest test that
        // rule had ever been given — 2.7 MB of vendored C++ that every audit
        // would have had to read. And the model import is gone, which was a
        // 500 MB file from the user's storage parsed by that C++: the single
        // widest inlet the app had.
        //
        // `tool/verify_no_sockets.sh` stays as a release gate. It has nothing
        // to check today and says so; it exists for the day somebody adds
        // native code again.
    }

    // The signing argument is at the top of this file, above `releaseKeyFile`.
    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = releaseKeyProperties["keyAlias"] as String
                keyPassword = releaseKeyProperties["keyPassword"] as String
                storeFile = file(releaseKeyProperties["storeFile"] as String)
                storePassword = releaseKeyProperties["storePassword"] as String
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────
    //  WHAT SHIPS, AND WHAT A PERSON WITH THE APK CAN SEE
    //
    //  Asked for as "nobody must know what the app code is". That is worth
    //  being precise about, because it is achievable in one sense and
    //  impossible in another, and pretending otherwise would be the kind of
    //  claim CLAUDE.md rule 10 forbids.
    //
    //  **What obfuscation genuinely buys.** R8 renames every class, method and
    //  field to `a.b.c`, inlines what it can, and deletes everything nothing
    //  reaches. A decompiled build is then a few thousand single-letter
    //  symbols with no structure, which is the difference between reading the
    //  code in an afternoon and reverse-engineering it over weeks. It also
    //  strips the strings and stack traces that would otherwise hand an
    //  attacker a map. Dart gets the same treatment via `--obfuscate
    //  --split-debug-info`; see BUILDING.md.
    //
    //  **What it does not buy, stated plainly.** Anything that runs on a
    //  device the attacker controls can, with enough time, be understood. This
    //  raises the cost; it does not make the app unreadable, and nothing does.
    //
    //  **Which is fine, and here is why it is fine.** The security of this app
    //  does not rest on the code being secret. It rests on Argon2id at 256 MiB
    //  and XChaCha20-Poly1305, both of which are public, documented, and
    //  designed to be safe *while the attacker holds the algorithm*. That is
    //  the whole of Kerckhoffs's principle and it is 140 years old. An app
    //  whose safety depended on nobody reading its source would be an app with
    //  no security at all — and this one publishes its source on purpose.
    //
    //  So obfuscation here is the outer wall, not the vault. It costs one
    //  build flag and it removes the casual attacker entirely.
    // ─────────────────────────────────────────────────────────────────────
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // No debuggable release, no test-only flag, no profiling hooks.
            // Each of these is the default; each is stated because a default
            // is something somebody can change without noticing they did.
            isDebuggable = false
            isJniDebuggable = false

            // ── Which processors ship ────────────────────────────────────
            //
            // Release only, so the debug build keeps x86_64 and still runs on
            // an emulator.
            //
            // ⚠ THIS BLOCK ALONE DOES NOT WORK, AND ITS COMMENT USED TO CLAIM
            // IT DID. It said the fat APK "went from 71 MB to about 45 with
            // this one block". Measured on 29 August 2026, the release APK was
            // 78.5 MB and contained **all three** slices — arm64 26.06 MB,
            // armeabi-v7a 22.91 MB and x86_64 **28.51 MB**. A third of what
            // people were downloading was an architecture no phone has.
            //
            // `ndk.abiFilters` governs libraries the Android plugin builds
            // itself, through `externalNativeBuild`. There has been no such
            // build here since whisper.cpp was removed. Every `.so` in this
            // APK — libflutter, libapp, libsqlcipher, libsodium, libdartjni —
            // arrives as a prebuilt **jniLib**, and this filter never sees one.
            // It was written when there *was* a CMake step, and it kept working
            // in the sense that it kept compiling.
            //
            // Kept because it is correct and free the day native code returns.
            // The line that actually removes the slice is the
            // `androidComponents` block below the `android { }` block.
            ndk {
                abiFilters += listOf("arm64-v8a", "armeabi-v7a")
            }

            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // Local development only. A release built this way installs and
                // runs, and can NEVER be updated by a properly signed one.
                logger.warn(
                    "\n" +
                        "  ⚠  No android/key.properties — signing the release build with the DEBUG key.\n" +
                        "     Fine for testing on your own phone. NEVER publish this: a debug-signed\n" +
                        "     release cannot be updated later, and every user would have to uninstall\n" +
                        "     and lose their vault to move to a real build.\n"
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  THE LINE THAT ACTUALLY DROPS x86_64 — 28 MB OF THE 78 THAT SHIPPED
// ─────────────────────────────────────────────────────────────────────────────
//
//  > *"Idk how but my app feels so heavy and large you can make it light"*
//
//  He was right, and it was not the fonts and not the code. The release APK
//  carried three complete copies of the engine, one per processor family, and
//  a phone runs exactly one of them. The x86_64 copy exists for emulators.
//
//  `packaging.jniLibs.excludes` is the filter that applies to **prebuilt**
//  native libraries, which is what all of ours are. It is reached per variant
//  through `androidComponents` rather than in a plain `packaging { }` block,
//  and that is deliberate: a plain block has no notion of build type and would
//  strip x86_64 from the debug build too, which is the build that has to run
//  on an emulator. Release is filtered; debug is left alone.
//
//  Verified by measurement rather than by belief — `tool/verify_no_internet.sh`
//  now prints the slices in the artefact it checks, so the next person does not
//  have to take this comment's word for it. The previous comment's word was
//  wrong for weeks.
//
//  `--split-per-abi` remains the smaller option — roughly 24 MB per device —
//  but it produces one APK per architecture and somebody has to pick. This is
//  the floor for the single file that can be handed to anybody.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.add("**/x86_64/**")
        variant.packaging.jniLibs.excludes.add("**/x86/**")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  The three Android libraries in the project, and what they buy.
//
//  CLAUDE.md rule 4 asks for a justification for every dependency, and these
//  are dependencies even though they are not in pubspec.yaml. Both are
//  first-party AndroidX, both are tiny, and both exist to AVOID a much larger
//  Flutter plugin:
//
//    core       FileProvider, so the camera app can write a photo into our own
//               cache. The alternative is image_picker, which pulls in its own
//               plugin, its own activity and its own temp-file handling that we
//               would then have to audit for rule 2.
//
//    documentfile
//               DocumentFile, for writing an automatic backup into the folder
//               the user granted. The alternative is a file-manager plugin with
//               a far wider surface than "put this one file in that one folder".
//
//  Between them they are why the manifest has one permission instead of four.
//  The third is below, with its own reason.
// ─────────────────────────────────────────────────────────────────────────────
dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.documentfile:documentfile:1.0.1")

    //  biometric  BiometricPrompt and, more importantly, the Keystore binding
    //             that makes a fingerprint gate a key rather than gate a
    //             boolean. local_auth would be the Flutter answer and it wraps
    //             this same library while making the CryptoObject harder to
    //             reach — and the CryptoObject is the entire security value.
    implementation("androidx.biometric:biometric:1.1.0")
}

flutter {
    source = "../.."
}
