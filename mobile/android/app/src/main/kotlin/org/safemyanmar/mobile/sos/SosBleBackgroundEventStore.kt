package org.safemyanmar.mobile.sos

import android.content.Context
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties

internal data class StoredSosBleEvent(
    val eventId: String,
    val payloads: List<ByteArray>,
    val rssi: Int?,
    val expiresAtMillis: Long,
    val senderToken: String?,
    val eventSequence: Int?,
    val hasBaseFrame: Boolean,
) {
    val payload: ByteArray
        get() = payloads.first()
}

internal class SosBleBackgroundEventStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

    @Synchronized
    fun setNotificationLanguage(languageCode: String) {
        preferences.edit()
            .putString(LANGUAGE_KEY, if (languageCode == "my") "my" else "en")
            .apply()
    }

    @Synchronized
    fun notificationLanguage(): String =
        preferences.getString(LANGUAGE_KEY, "en")?.let {
            if (it == "my") "my" else "en"
        } ?: "en"

    @Synchronized
    fun add(payload: ByteArray, rssi: Int?, nowMillis: Long = System.currentTimeMillis()): StoredSosBleEvent? {
        val frame = SosBleFrameValidator.validate(payload, nowMillis) ?: return null
        if (isOriginatedEvent(frame.eventId, nowMillis)) return null
        val events = read(nowMillis).toMutableList()
        var existingMetadataPayloads = emptyList<ByteArray>()
        val sameIndex = events.indexOfFirst { it.eventId == frame.eventId }
        if (sameIndex >= 0) {
            val existing = events[sameIndex]
            if (frame.metadata) {
                if (existing.payloads.any { it.contentEquals(payload) }) return null
                events[sameIndex] = existing.copy(
                    payloads = existing.payloads + payload.copyOf(),
                )
                write(events)
                return null
            }
            if (existing.hasBaseFrame) return null
            existingMetadataPayloads = existing.payloads
            events.removeAt(sameIndex)
        }
        val highWater = readHighWater()
        if (!frame.metadata && frame.senderToken != null && frame.eventSequence != null) {
            val latestSequence = highWater[frame.senderToken]
            if (latestSequence != null && frame.eventSequence <= latestSequence) return null
        }
        val replacementIndex = frame.senderToken?.let { senderToken ->
            events.indexOfFirst { it.senderToken == senderToken }
        } ?: -1
        if (replacementIndex >= 0 && !frame.metadata) {
            val previous = events[replacementIndex]
            if (frame.eventSequence == null ||
                previous.eventSequence == null ||
                frame.eventSequence <= previous.eventSequence
            ) {
                return null
            }
            events.removeAt(replacementIndex)
        }
        val stored = StoredSosBleEvent(
            eventId = frame.eventId,
            payloads = existingMetadataPayloads + payload.copyOf(),
            rssi = rssi,
            expiresAtMillis = frame.createdAtMillis + frame.ttlMinutes * 60_000L,
            senderToken = frame.senderToken,
            eventSequence = frame.eventSequence,
            hasBaseFrame = !frame.metadata,
        )
        events.add(stored)
        while (events.size > MAX_EVENTS) events.removeAt(0)
        if (!frame.metadata && frame.senderToken != null && frame.eventSequence != null) {
            highWater[frame.senderToken] = frame.eventSequence
            while (highWater.size > MAX_EVENTS) {
                highWater.remove(highWater.keys.first())
            }
            writeHighWater(highWater)
        }
        write(events)
        return if (frame.metadata) null else stored
    }

    @Synchronized
    fun read(nowMillis: Long = System.currentTimeMillis()): List<StoredSosBleEvent> {
        val encrypted = preferences.getString(EVENTS_KEY, null) ?: return emptyList()
        val events = try {
            decode(encrypted)
        } catch (_: Throwable) {
            emptyList()
        }
        val active = events.filter { it.expiresAtMillis >= nowMillis }
        if (active.size != events.size) write(active)
        return active
    }

    @Synchronized
    fun isEnabled(): Boolean = preferences.getBoolean(ENABLED_KEY, false)

    @Synchronized
    fun setEnabled(enabled: Boolean) {
        preferences.edit().putBoolean(ENABLED_KEY, enabled).apply()
    }

    fun rememberOriginatedEvent(
        eventId: String,
        expiresAtMillis: Long,
        nowMillis: Long = System.currentTimeMillis(),
    ): Boolean = synchronized(ORIGIN_LOCK) {
        if (!EVENT_ID_PATTERN.matches(eventId) || expiresAtMillis <= nowMillis) return false
        return try {
            val events = readOriginatedEvents(nowMillis)
            events[eventId] = expiresAtMillis
            while (events.size > MAX_EVENTS) {
                events.remove(events.keys.first())
            }
            writeOriginatedEvents(events)
        } catch (_: Throwable) {
            false
        }
    }

    fun isOriginatedEvent(
        eventId: String,
        nowMillis: Long = System.currentTimeMillis(),
    ): Boolean = synchronized(ORIGIN_LOCK) {
        if (!EVENT_ID_PATTERN.matches(eventId)) return false
        return try {
            readOriginatedEvents(nowMillis).getOrDefault(eventId, 0L) >= nowMillis
        } catch (_: Throwable) {
            false
        }
    }

    fun asFlutterEvents(nowMillis: Long = System.currentTimeMillis()): List<Map<String, Any?>> =
        read(nowMillis).flatMap { event ->
            event.payloads.map { payload ->
                mapOf(
                    "data" to payload,
                    "rssi" to event.rssi,
                    "background" to true,
                )
            }
        }

    private fun write(events: List<StoredSosBleEvent>) {
        val json = JSONArray()
        events.forEach { event ->
            json.put(
                JSONObject().apply {
                    put("event_id", event.eventId)
                    put(
                        "payloads",
                        JSONArray().apply {
                            event.payloads.forEach { payload ->
                                put(Base64.encodeToString(payload, Base64.NO_WRAP))
                            }
                        },
                    )
                    put("rssi", event.rssi ?: JSONObject.NULL)
                    put("expires_at", event.expiresAtMillis)
                },
            )
        }
        preferences.edit().putString(EVENTS_KEY, seal(json.toString())).apply()
    }

    private fun readHighWater(): MutableMap<String, Int> {
        val encrypted = preferences.getString(HIGH_WATER_KEY, null) ?: return mutableMapOf()
        return try {
            val json = JSONObject(open(encrypted))
            buildMap {
                val keys = json.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val value = json.optInt(key, -1)
                    if (key.matches(Regex("^[0-9a-f]{8}$")) && value >= 0) {
                        put(key, value)
                    }
                }
            }.toMutableMap()
        } catch (_: Throwable) {
            mutableMapOf()
        }
    }

    private fun writeHighWater(highWater: Map<String, Int>) {
        val json = JSONObject()
        highWater.forEach { (senderToken, sequence) -> json.put(senderToken, sequence) }
        preferences.edit().putString(HIGH_WATER_KEY, seal(json.toString())).apply()
    }

    private fun readOriginatedEvents(nowMillis: Long): MutableMap<String, Long> {
        val encrypted = preferences.getString(ORIGINATED_KEY, null) ?: return mutableMapOf()
        val json = JSONObject(open(encrypted))
        val active = buildMap {
            val keys = json.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val expiresAt = json.optLong(key, 0L)
                if (EVENT_ID_PATTERN.matches(key) && expiresAt >= nowMillis) {
                    put(key, expiresAt)
                }
            }
        }.toMutableMap()
        if (active.size != json.length()) writeOriginatedEvents(active)
        return active
    }

    private fun writeOriginatedEvents(events: Map<String, Long>): Boolean {
        val json = JSONObject()
        events.forEach { (eventId, expiresAt) -> json.put(eventId, expiresAt) }
        return preferences.edit().putString(ORIGINATED_KEY, seal(json.toString())).commit()
    }

    private fun decode(value: String): List<StoredSosBleEvent> {
        val json = JSONArray(open(value))
        return buildList {
            for (index in 0 until json.length()) {
                val item = json.getJSONObject(index)
                val payloads = if (item.has("payloads")) {
                    val encodedPayloads = item.getJSONArray("payloads")
                    buildList {
                        for (payloadIndex in 0 until encodedPayloads.length()) {
                            add(
                                Base64.decode(
                                    encodedPayloads.getString(payloadIndex),
                                    Base64.DEFAULT,
                                ),
                            )
                        }
                    }
                } else {
                    listOf(Base64.decode(item.getString("payload"), Base64.DEFAULT))
                }
                if (payloads.isEmpty()) continue
                val eventId = item.getString("event_id")
                val validatedFrames = payloads.mapNotNull {
                    SosBleFrameValidator.validate(it, item.getLong("expires_at"))
                }
                if (validatedFrames.size != payloads.size ||
                    validatedFrames.any { it.eventId != eventId }
                ) continue
                val baseFrame = validatedFrames.firstOrNull { !it.metadata }
                val rssi = if (item.isNull("rssi")) null else item.getInt("rssi")
                add(
                    StoredSosBleEvent(
                        eventId = eventId,
                        payloads = payloads,
                        rssi = rssi,
                        senderToken = (baseFrame ?: validatedFrames.first()).senderToken,
                        eventSequence = (baseFrame ?: validatedFrames.first()).eventSequence,
                        hasBaseFrame = baseFrame != null,
                        expiresAtMillis = item.getLong("expires_at"),
                    ),
                )
            }
        }
    }

    private fun seal(value: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        val combined = ByteArray(cipher.iv.size + encrypted.size)
        cipher.iv.copyInto(combined)
        encrypted.copyInto(combined, cipher.iv.size)
        return Base64.encodeToString(combined, Base64.NO_WRAP)
    }

    private fun open(value: String): String {
        val combined = Base64.decode(value, Base64.DEFAULT)
        require(combined.size > GCM_IV_LENGTH_BYTES)
        val iv = combined.copyOfRange(0, GCM_IV_LENGTH_BYTES)
        val encrypted = combined.copyOfRange(GCM_IV_LENGTH_BYTES, combined.size)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv))
        return cipher.doFinal(encrypted).toString(Charsets.UTF_8)
    }

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
        (keyStore.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEY_STORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    companion object {
        private const val PREFERENCES = "sos_ble_background_events"
        private const val EVENTS_KEY = "events"
        private const val HIGH_WATER_KEY = "sender_high_water"
        private const val ORIGINATED_KEY = "originated_events"
        private const val ENABLED_KEY = "enabled"
        private const val LANGUAGE_KEY = "notification_language"
        private const val MAX_EVENTS = 64
        private val ORIGIN_LOCK = Any()
        private val EVENT_ID_PATTERN = Regex("^[0-9a-f]{16}$")
        private const val ANDROID_KEY_STORE = "AndroidKeyStore"
        private const val KEY_ALIAS = "sos_ble_background_events_key"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val GCM_IV_LENGTH_BYTES = 12
        private const val GCM_TAG_LENGTH_BITS = 128
    }
}
