package org.safemyanmar.mobile.sos

import kotlin.math.abs

internal data class ValidatedSosBleFrame(
    val eventId: String,
    val createdAtMillis: Long,
    val ttlMinutes: Int,
    val senderToken: String?,
    val eventSequence: Int?,
    val metadata: Boolean,
)

/** Mirrors the Dart codec so untrusted frames are rejected before persistence. */
internal object SosBleFrameValidator {
    private const val MARKER = 0x53
    private const val EXACT_VERSION = 3
    private const val METADATA_VERSION = 4
    private const val METADATA_FRAME_TYPE = 1
    private const val APPROXIMATE_VERSION = 2
    private const val LEGACY_VERSION = 1
    private const val MAX_HOPS = 1
    private const val METADATA_FRAME_LENGTH = 26
    private const val METADATA_CHUNK_SIZE = 6
    private const val METADATA_MAX_BYTES = 66
    private const val METADATA_MAX_FRAMES = 11
    private const val EPOCH_MINUTES = 1_704_067_200L / 60L

    fun validate(payload: ByteArray, nowMillis: Long = System.currentTimeMillis()): ValidatedSosBleFrame? {
        if (payload.size < 2 || payload[0].toInt() and 0xff != MARKER) return null
        val version = payload[1].toInt() and 0xff
        val exact = version == EXACT_VERSION
        val metadata = version == METADATA_VERSION &&
            payload.size >= 3 && payload[2].toInt() and 0xff == METADATA_FRAME_TYPE
        val approximate = version == APPROXIMATE_VERSION
        val legacy = version == LEGACY_VERSION
        if (!exact && !metadata && !approximate && !legacy) return null

        val expectedLength = if (exact || metadata) METADATA_FRAME_LENGTH else 22
        if (payload.size != expectedLength) return null
        val checksumOffset = if (exact || metadata) 24 else 20
        val expectedChecksum = readUnsignedShort(payload, checksumOffset)
        if (crc16(payload, checksumOffset) != expectedChecksum) return null

        val flags = payload[3].toInt() and 0xff
        val ttlMinutes = flags and 0x0f
        val hopCount = if (legacy) 0 else flags ushr 4
        if (ttlMinutes !in 1..15 || hopCount > MAX_HOPS) return null

        val relativeMinutes = ((payload[12].toInt() and 0xff) shl 16) or
            ((payload[13].toInt() and 0xff) shl 8) or
            (payload[14].toInt() and 0xff)
        val createdAtMillis = (EPOCH_MINUTES + relativeMinutes) * 60_000L
        val ageMillis = nowMillis - createdAtMillis
        if (ageMillis < 0L || ageMillis > ttlMinutes * 60_000L) return null

        val eventId = eventId(payload) ?: return null
        val senderMetadata = parseSenderMetadata(payload)
        if (metadata) {
            val index = payload[15].toInt() and 0xff
            val total = payload[16].toInt() and 0xff
            val totalDataLength = payload[17].toInt() and 0xff
            if (index >= total ||
                total !in 1..METADATA_MAX_FRAMES ||
                totalDataLength !in 2..METADATA_MAX_BYTES ||
                index * METADATA_CHUNK_SIZE >= totalDataLength
            ) return null
            val expectedDataLength = minOf(
                METADATA_CHUNK_SIZE,
                totalDataLength - index * METADATA_CHUNK_SIZE,
            )
            for (offset in expectedDataLength until METADATA_CHUNK_SIZE) {
                if (payload[18 + offset].toInt() != 0) return null
            }
            return ValidatedSosBleFrame(
                eventId = eventId,
                createdAtMillis = createdAtMillis,
                ttlMinutes = ttlMinutes,
                senderToken = senderMetadata?.first,
                eventSequence = senderMetadata?.second,
                metadata = true,
            )
        }

        val locationStatus = payload[2].toInt() and 0xff
        if (locationStatus !in 0..2) return null

        val batteryOffset = if (exact) 23 else 19
        val battery = payload[batteryOffset].toInt() and 0xff
        if (battery != 0xff && battery > 100) return null

        if (exact) {
            val latitude = readInt(payload, 15) / 1_000_000.0
            val longitude = readInt(payload, 19) / 1_000_000.0
            if (locationStatus == 2) {
                if (readInt(payload, 15) != 0 || readInt(payload, 19) != 0) return null
            } else if (!validCoordinate(latitude, longitude)) {
                return null
            }
        } else {
            val latitude = readShort(payload, 15) / 100.0
            val longitude = readShort(payload, 17) / 100.0
            if (locationStatus == 2) {
                if (readShort(payload, 15) != 0 || readShort(payload, 17) != 0) return null
            } else if (!validCoordinate(latitude, longitude)) {
                return null
            }
        }

        return ValidatedSosBleFrame(
            eventId = eventId,
            createdAtMillis = createdAtMillis,
            ttlMinutes = ttlMinutes,
            senderToken = senderMetadata?.first,
            eventSequence = senderMetadata?.second,
            metadata = false,
        )
    }

    private fun parseSenderMetadata(payload: ByteArray): Pair<String, Int>? {
        if (payload[4].toInt() and 0xff != SENDER_MARKER ||
            payload[5].toInt() and 0xff != SENDER_VERSION
        ) {
            return null
        }
        val token = payload.copyOfRange(6, 10).joinToString("") {
            (it.toInt() and 0xff).toString(16).padStart(2, '0')
        }
        return token to readUnsignedShort(payload, 10)
    }

    fun eventId(payload: ByteArray): String? {
        if (payload.size < 12 || payload[0].toInt() and 0xff != MARKER) return null
        return payload.copyOfRange(4, 12).joinToString("") {
            (it.toInt() and 0xff).toString(16).padStart(2, '0')
        }
    }

    private fun validCoordinate(latitude: Double, longitude: Double): Boolean =
        latitude.isFinite() && longitude.isFinite() &&
            abs(latitude) <= 90.0 && abs(longitude) <= 180.0

    private fun readUnsignedShort(bytes: ByteArray, offset: Int): Int =
        ((bytes[offset].toInt() and 0xff) shl 8) or (bytes[offset + 1].toInt() and 0xff)

    private fun readShort(bytes: ByteArray, offset: Int): Int {
        val value = readUnsignedShort(bytes, offset)
        return if (value >= 0x8000) value - 0x10000 else value
    }

    private fun readInt(bytes: ByteArray, offset: Int): Int {
        val value = ((bytes[offset].toInt() and 0xff) shl 24) or
            ((bytes[offset + 1].toInt() and 0xff) shl 16) or
            ((bytes[offset + 2].toInt() and 0xff) shl 8) or
            (bytes[offset + 3].toInt() and 0xff)
        return value
    }

    private fun crc16(bytes: ByteArray, endExclusive: Int): Int {
        var crc = 0xffff
        for (index in 0 until endExclusive) {
            crc = crc xor ((bytes[index].toInt() and 0xff) shl 8)
            repeat(8) {
                crc = if (crc and 0x8000 != 0) {
                    (crc shl 1) xor 0x1021
                } else {
                    crc shl 1
                }
                crc = crc and 0xffff
            }
        }
        return crc
    }

    private const val SENDER_MARKER = 0xa5
    private const val SENDER_VERSION = 0x5a
}
