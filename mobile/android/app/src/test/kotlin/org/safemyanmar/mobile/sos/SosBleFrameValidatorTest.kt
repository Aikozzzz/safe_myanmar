package org.safemyanmar.mobile.sos

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class SosBleFrameValidatorTest {
    @Test
    fun acceptsCurrentFrameAndExtractsMetadata() {
        val now = EPOCH_MILLIS + 10 * MINUTE_MILLIS + 30_000L
        val payload = frame(
            eventId = byteArrayOf(1, 2, 3, 4, 5, 6, 7, 8),
            createdAtMillis = EPOCH_MILLIS + 9 * MINUTE_MILLIS,
            ttlMinutes = 5,
            latitude = 16.8409,
            longitude = 96.1735,
            battery = 80,
        )

        val result = SosBleFrameValidator.validate(payload, now)

        assertNotNull(result)
        assertEquals("0102030405060708", result?.eventId)
        assertEquals(EPOCH_MILLIS + 9 * MINUTE_MILLIS, result?.createdAtMillis)
        assertEquals(5, result?.ttlMinutes)
    }

    @Test
    fun extractsStructuredSenderMetadataFromEventId() {
        val now = EPOCH_MILLIS + 10 * MINUTE_MILLIS
        val payload = frame(
            eventId = byteArrayOf(
                0xa5.toByte(), 0x5a, 0x01, 0x02, 0x03, 0x04, 0x00, 0x2a,
            ),
            createdAtMillis = now - MINUTE_MILLIS,
        )

        val result = SosBleFrameValidator.validate(payload, now)

        assertEquals("01020304", result?.senderToken)
        assertEquals(42, result?.eventSequence)
    }

    @Test
    fun rejectsUnsupportedVersionAndBadChecksum() {
        val now = EPOCH_MILLIS + 10 * MINUTE_MILLIS
        val unsupported = frame(version = 9, createdAtMillis = now - MINUTE_MILLIS)
        val badChecksum = frame(createdAtMillis = now - MINUTE_MILLIS).also {
            it[24] = (it[24].toInt() xor 0xff).toByte()
        }

        assertNull(SosBleFrameValidator.validate(unsupported, now))
        assertNull(SosBleFrameValidator.validate(badChecksum, now))
    }

    @Test
    fun rejectsExpiredFutureAndOverRelayedFrames() {
        val now = EPOCH_MILLIS + 10 * MINUTE_MILLIS
        val expired = frame(createdAtMillis = EPOCH_MILLIS + 4 * MINUTE_MILLIS, ttlMinutes = 5)
        val future = frame(createdAtMillis = EPOCH_MILLIS + 11 * MINUTE_MILLIS)
        val overRelayed = frame(createdAtMillis = now - MINUTE_MILLIS, hopCount = 2)

        assertNull(SosBleFrameValidator.validate(expired, now))
        assertNull(SosBleFrameValidator.validate(future, now))
        assertNull(SosBleFrameValidator.validate(overRelayed, now))
    }

    @Test
    fun acceptsUnavailableLocationOnlyWhenCoordinatesAreZero() {
        val now = EPOCH_MILLIS + 10 * MINUTE_MILLIS
        val valid = frame(
            createdAtMillis = now - MINUTE_MILLIS,
            locationStatus = 2,
            latitude = 0.0,
            longitude = 0.0,
        )
        val populated = frame(
            createdAtMillis = now - MINUTE_MILLIS,
            locationStatus = 2,
            latitude = 16.0,
            longitude = 96.0,
        )

        assertNotNull(SosBleFrameValidator.validate(valid, now))
        assertNull(SosBleFrameValidator.validate(populated, now))
    }

    @Test
    fun rejectsCoordinatesOutsideMyanmarLocationBounds() {
        val now = EPOCH_MILLIS + 10 * MINUTE_MILLIS
        val invalid = frame(
            createdAtMillis = now - MINUTE_MILLIS,
            latitude = 91.0,
            longitude = 96.0,
        )

        assertNull(SosBleFrameValidator.validate(invalid, now))
    }

    private fun frame(
        eventId: ByteArray = byteArrayOf(1, 2, 3, 4, 5, 6, 7, 8),
        version: Int = 3,
        locationStatus: Int = 0,
        hopCount: Int = 0,
        ttlMinutes: Int = 5,
        createdAtMillis: Long,
        latitude: Double = 16.8409,
        longitude: Double = 96.1735,
        battery: Int = 80,
    ): ByteArray {
        val exact = version == 3
        val payload = ByteArray(if (exact) 26 else 22)
        payload[0] = 0x53
        payload[1] = version.toByte()
        payload[2] = locationStatus.toByte()
        payload[3] = ((if (version == 1) 0 else hopCount) shl 4 or ttlMinutes).toByte()
        eventId.copyInto(payload, 4)

        val relativeMinutes = ((createdAtMillis - EPOCH_MILLIS) / MINUTE_MILLIS).toInt()
        payload[12] = (relativeMinutes ushr 16).toByte()
        payload[13] = (relativeMinutes ushr 8).toByte()
        payload[14] = relativeMinutes.toByte()
        if (exact) {
            writeInt(payload, 15, (latitude * 1_000_000).toInt())
            writeInt(payload, 19, (longitude * 1_000_000).toInt())
            payload[23] = battery.toByte()
        } else {
            writeShort(payload, 15, (latitude * 100).toInt())
            writeShort(payload, 17, (longitude * 100).toInt())
            payload[19] = battery.toByte()
        }
        val checksumOffset = if (exact) 24 else 20
        val checksum = crc16(payload, checksumOffset)
        payload[checksumOffset] = (checksum ushr 8).toByte()
        payload[checksumOffset + 1] = checksum.toByte()
        return payload
    }

    private fun writeShort(payload: ByteArray, offset: Int, value: Int) {
        payload[offset] = (value ushr 8).toByte()
        payload[offset + 1] = value.toByte()
    }

    private fun writeInt(payload: ByteArray, offset: Int, value: Int) {
        payload[offset] = (value ushr 24).toByte()
        payload[offset + 1] = (value ushr 16).toByte()
        payload[offset + 2] = (value ushr 8).toByte()
        payload[offset + 3] = value.toByte()
    }

    private fun crc16(payload: ByteArray, endExclusive: Int): Int {
        var crc = 0xffff
        for (index in 0 until endExclusive) {
            crc = crc xor ((payload[index].toInt() and 0xff) shl 8)
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

    private companion object {
        const val EPOCH_MILLIS = 1_704_067_200_000L
        const val MINUTE_MILLIS = 60_000L
    }
}
