package com.probablypiyush.lamplight

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * The third envelope.
 *
 * `02-security/SECURITY-ARCHITECTURE.md` §1 describes the vault key as a single
 * random DEK sealed several times over — "three sealed envelopes, each
 * containing the same key, each opened a different way: the passcode, the
 * recovery phrase, and (later) the phone's hardware key store." This is later.
 *
 * WHAT IS ACTUALLY SEALED HERE, AND WHY IT IS NOT THE DEK
 *
 * Android's keystore encrypts a **32-byte secret of ours**, not the vault's
 * DEK. Dart wraps the DEK under that secret with the same XChaCha20-Poly1305
 * envelope it uses for the passcode and the recovery phrase, and only the
 * envelope goes in the keyring file.
 *
 * The reason is what crosses the method channel. The DEK opens everything the
 * user has ever written; a per-device biometric secret opens one envelope on
 * one phone. Both have to cross once at enrolment and once at each unlock, and
 * it is worth a few lines to make the thing that crosses the smaller of the
 * two. It also means the biometric wrapper is structurally identical to the
 * other two, which is the architecture the document actually describes.
 *
 * WHAT THE KEYSTORE GIVES US THAT WE CANNOT GIVE OURSELVES
 *
 * The key below never exists in this process's memory. It lives in the secure
 * element or the TEE, it cannot be exported, and `setUserAuthenticationRequired`
 * means the hardware itself refuses to use it until a fingerprint or a face has
 * been verified. An attacker with the phone's filesystem — the whole of
 * `THREAT-MODEL.md`'s adversary #2 — gets the keyring, gets the envelope, and
 * cannot open it without the finger.
 *
 * THE ENROLMENT TRAP, WHICH IS A REAL ATTACK AND IS CLOSED
 *
 * `setInvalidatedByBiometricEnrollment(true)`. Without it, somebody who can
 * unlock the phone once — a partner who knows the PIN — can add *their own*
 * fingerprint in Settings and from then on open the vault with it. With it, the
 * moment a new biometric is enrolled the keystore key is destroyed and the
 * biometric envelope is dead; the passcode still works, and Lamplight quietly
 * asks whether to set it up again. `09-build/09-build/SAFETY-PROMPTS.md` names
 * this one specifically.
 *
 * BIOMETRIC_STRONG ONLY. Class 3 — the tier that can be bound to a key at all.
 * Face unlock on most Android phones is class 2 and cannot gate a keystore key;
 * accepting it would mean a prompt that looks like security and is a formality.
 */
class BiometricVault(private val activity: FragmentActivity) {

    /** Whether this device has usable, enrolled, key-bindable biometrics. */
    fun status(): String {
        val manager = BiometricManager.from(activity)
        return when (manager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> "ready"
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> "none_enrolled"
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE,
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> "no_hardware"
            else -> "unavailable"
        }
    }

    /**
     * Seals [secret] behind the user's fingerprint. Returns the sealed bytes.
     *
     * Shows the prompt: enrolling is a deliberate act and confirming it with the
     * finger you are about to rely on is also the only way to be sure that
     * finger works before depending on it.
     */
    fun enrol(
        secret: ByteArray,
        title: String,
        subtitle: String,
        onDone: (Map<String, String>?) -> Unit,
        onError: (String) -> Unit,
    ) {
        val key = try {
            createKey()
        } catch (e: Exception) {
            onError(e.message ?: "This phone would not create a secure key.")
            return
        }

        val cipher = Cipher.getInstance(TRANSFORMATION)
        try {
            cipher.init(Cipher.ENCRYPT_MODE, key)
        } catch (e: Exception) {
            onError(e.message ?: "The secure key could not be used.")
            return
        }

        prompt(cipher, title, subtitle, onError) { authenticated ->
            val sealed = authenticated.doFinal(secret)
            onDone(
                mapOf(
                    "sealed" to Base64.encodeToString(sealed, Base64.NO_WRAP),
                    "iv" to Base64.encodeToString(authenticated.iv, Base64.NO_WRAP)
                )
            )
        }
    }

    /** Opens what [enrol] sealed. */
    fun unlock(
        sealedB64: String,
        ivB64: String,
        title: String,
        subtitle: String,
        onDone: (ByteArray?) -> Unit,
        onError: (String) -> Unit,
    ) {
        val key = existingKey()
        if (key == null) {
            // The key is gone. Almost always because a biometric was added or
            // removed, which destroys it on purpose — see the class comment.
            onError(INVALIDATED)
            return
        }

        val cipher = Cipher.getInstance(TRANSFORMATION)
        try {
            cipher.init(
                Cipher.DECRYPT_MODE,
                key,
                GCMParameterSpec(TAG_BITS, Base64.decode(ivB64, Base64.NO_WRAP))
            )
        } catch (e: Exception) {
            // KeyPermanentlyInvalidatedException lands here.
            onError(INVALIDATED)
            return
        }

        prompt(cipher, title, subtitle, onError) { authenticated ->
            onDone(authenticated.doFinal(Base64.decode(sealedB64, Base64.NO_WRAP)))
        }
    }

    /** Forgets the key. The passcode is unaffected. */
    fun clear() {
        try {
            KeyStore.getInstance(PROVIDER).apply { load(null) }.deleteEntry(ALIAS)
        } catch (_: Exception) {
        }
    }

    // ─────────────────────────────────────────────────────────────────────────

    private fun prompt(
        cipher: Cipher,
        title: String,
        subtitle: String,
        onError: (String) -> Unit,
        onSuccess: (Cipher) -> Unit,
    ) {
        val prompt = BiometricPrompt(
            activity,
            androidx.core.content.ContextCompat.getMainExecutor(activity),
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult
                ) {
                    val authenticated = result.cryptoObject?.cipher
                    if (authenticated == null) {
                        onError("The fingerprint was accepted but no key came back.")
                        return
                    }
                    try {
                        onSuccess(authenticated)
                    } catch (e: Exception) {
                        onError(e.message ?: "That could not be unsealed.")
                    }
                }

                override fun onAuthenticationError(code: Int, message: CharSequence) {
                    // Cancelling is not a failure, and must not be shown as one.
                    if (code == BiometricPrompt.ERROR_USER_CANCELED ||
                        code == BiometricPrompt.ERROR_NEGATIVE_BUTTON ||
                        code == BiometricPrompt.ERROR_CANCELED
                    ) {
                        onError(CANCELLED)
                    } else {
                        onError(message.toString())
                    }
                }
            }
        )

        prompt.authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setSubtitle(subtitle)
                // The passcode is always the way through. Never a dead end.
                .setNegativeButtonText("Use passcode")
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                .setConfirmationRequired(false)
                .build(),
            BiometricPrompt.CryptoObject(cipher)
        )
    }

    private fun createKey(): SecretKey {
        val generator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES, PROVIDER
        )
        generator.init(
            KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                // The hardware refuses to use this key until a finger is
                // verified. Not a check we perform — a check we cannot skip.
                .setUserAuthenticationRequired(true)
                // Adding a fingerprint destroys the key. See the class comment:
                // without this, anyone who can unlock the phone once can enrol
                // their own finger and inherit the vault.
                .setInvalidatedByBiometricEnrollment(true)
                .build()
        )
        return generator.generateKey()
    }

    private fun existingKey(): SecretKey? = try {
        val store = KeyStore.getInstance(PROVIDER).apply { load(null) }
        store.getKey(ALIAS, null) as? SecretKey
    } catch (_: Exception) {
        null
    }

    companion object {
        private const val PROVIDER = "AndroidKeyStore"

        /**
         * Versioned. If the parameters above ever have to change, the new key
         * gets a new alias rather than silently replacing one that existing
         * vaults depend on.
         */
        private const val ALIAS = "lamplight.biometric.v1"

        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val TAG_BITS = 128

        const val CANCELLED = "cancelled"
        const val INVALIDATED = "invalidated"
    }
}
