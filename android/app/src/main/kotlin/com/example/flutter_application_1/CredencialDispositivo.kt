package com.example.flutter_application_1

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.spec.GCMParameterSpec

/** Credencial aleatoria por cuenta/instalación. No usa IMEI ni Android ID. */
class CredencialDispositivo(private val context: Context) {
    @Synchronized
    fun obtener(uid: String): Map<String, String> {
        require(uid.isNotBlank() && uid.length <= 256)
        val keyId = "crediasciende.dispositivo.v1"
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (!store.containsAlias(keyId)) {
            val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            generator.init(KeyGenParameterSpec.Builder(keyId,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build())
            generator.generateKey()
        }
        val key = store.getKey(keyId, null)
        val prefs = context.getSharedPreferences("dispositivo_protegido", Context.MODE_PRIVATE)
        val account = MessageDigest.getInstance("SHA-256").digest(uid.toByteArray())
            .joinToString("") { "%02x".format(it) }
        val saved = prefs.getString(account, null)
        val token: String
        if (saved != null) {
            val parts = saved.split(".")
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, Base64.decode(parts[0], Base64.NO_WRAP)))
            token = String(cipher.doFinal(Base64.decode(parts[1], Base64.NO_WRAP)), Charsets.UTF_8)
        } else {
            val bytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
            token = bytes.joinToString("") { "%02x".format(it) }
            bytes.fill(0)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.ENCRYPT_MODE, key)
            val encrypted = cipher.doFinal(token.toByteArray())
            check(prefs.edit().putString(account,
                Base64.encodeToString(cipher.iv, Base64.NO_WRAP) + "." +
                Base64.encodeToString(encrypted, Base64.NO_WRAP)).commit())
        }
        return mapOf("token" to token, "modelo" to "${Build.MANUFACTURER} ${Build.MODEL}")
    }
}
