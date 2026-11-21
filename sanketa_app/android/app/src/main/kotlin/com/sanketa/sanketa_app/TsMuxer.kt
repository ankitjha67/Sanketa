package com.sanketa.sanketa_app

import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream

class TsMuxer(private val sps: ByteArray? = null, private val pps: ByteArray? = null) {

    private var out: OutputStream? = null
    private var firstVideoPacket = true
    private val cc = IntArray(0x2000) // continuity counters per PID
    val isSegmentOpen: Boolean get() = out != null

    fun startSegment(file: File) {
        out = BufferedOutputStream(FileOutputStream(file), 188 * 64)
        firstVideoPacket = true
        writePat()
        writePmt()
    }

    fun writeVideoFrame(data: ByteArray, ptsUs: Long, isKeyframe: Boolean) {
        val pts90 = ptsUs * 90_000 / 1_000_000

        val nalData = if (isKeyframe && sps != null && pps != null) {
            ByteArray(sps.size + pps.size + data.size).also {
                sps.copyInto(it)
                pps.copyInto(it, sps.size)
                data.copyInto(it, sps.size + pps.size)
            }
        } else {
            data
        }

        val pesHeader = buildPesHeader(pts90)
        val payload = ByteArray(pesHeader.size + nalData.size)
        pesHeader.copyInto(payload)
        nalData.copyInto(payload, pesHeader.size)

        val needPcr = firstVideoPacket
        firstVideoPacket = false
        writePesPayload(PID_VIDEO, payload, needPcr, pts90, isKeyframe)
    }

    fun writeAudioFrame(adtsData: ByteArray, ptsUs: Long) {
        val pts90 = ptsUs * 90_000 / 1_000_000
        val pesHeader = buildPesHeader(pts90, 0xC0)
        val payload = ByteArray(pesHeader.size + adtsData.size)
        pesHeader.copyInto(payload)
        adtsData.copyInto(payload, pesHeader.size)
        writePesPayload(PID_AUDIO, payload, false, 0L, false)
    }

    fun endSegment() {
        out?.flush()
        out?.close()
        out = null
    }

    fun resetContinuityCounters() {
        cc.fill(0)
    }

    // ---- PAT ----------------------------------------------------------------

    private fun writePat() {
        val section = ByteArray(17)
        var i = 0
        section[i++] = 0x00 // pointer field
        section[i++] = 0x00 // table_id
        section[i++] = 0xB0.toByte()
        section[i++] = 0x0D // section_length (13 bytes follow)
        section[i++] = 0x00 // transport_stream_id high
        section[i++] = 0x01 // transport_stream_id low
        section[i++] = 0xC1.toByte()
        section[i++] = 0x00 // section_number
        section[i++] = 0x00 // last_section_number
        section[i++] = 0x00
        section[i++] = 0x01
        section[i++] = 0xF0.toByte()
        section[i++] = 0x00

        val crc = crc32(section, 1, 12)
        section[i++] = (crc shr 24).toByte()
        section[i++] = (crc shr 16).toByte()
        section[i++] = (crc shr 8).toByte()
        section[i++] = crc.toByte()

        writeSingleTsPacket(PID_PAT, section)
    }

    // ---- PMT ----------------------------------------------------------------

    private fun writePmt() {
        val section = ByteArray(27)
        var i = 0
        section[i++] = 0x00 // pointer field
        section[i++] = 0x02 // table_id (PMT)
        section[i++] = 0xB0.toByte()
        section[i++] = 0x17 // section_length (23 bytes follow)
        section[i++] = 0x00 // program_number high
        section[i++] = 0x01 // program_number low
        section[i++] = 0xC1.toByte()
        section[i++] = 0x00 // section_number
        section[i++] = 0x00 // last_section_number
        // PCR_PID = 0x0100
        section[i++] = 0xE1.toByte()
        section[i++] = 0x00
        // program_info_length = 0
        section[i++] = 0xF0.toByte()
        section[i++] = 0x00
        // video stream: stream_type=0x1B (H.264), PID=0x0100
        section[i++] = 0x1B
        section[i++] = 0xE1.toByte()
        section[i++] = 0x00
        section[i++] = 0xF0.toByte()
        section[i++] = 0x00
        // audio stream: stream_type=0x0F (AAC ADTS), PID=0x0101
        section[i++] = 0x0F
        section[i++] = 0xE1.toByte()
        section[i++] = 0x01
        section[i++] = 0xF0.toByte()
        section[i++] = 0x00

        val crc = crc32(section, 1, 22)
        section[i++] = (crc shr 24).toByte()
        section[i++] = (crc shr 16).toByte()
        section[i++] = (crc shr 8).toByte()
        section[i++] = crc.toByte()

        writeSingleTsPacket(PID_PMT, section)
    }

    // ---- PES header ---------------------------------------------------------

    private fun buildPesHeader(pts90: Long, streamId: Int = 0xE0): ByteArray {
        val header = ByteArray(14)
        var i = 0
        header[i++] = 0x00
        header[i++] = 0x00
        header[i++] = 0x01
        header[i++] = streamId.toByte()
        header[i++] = 0x00
        header[i++] = 0x00
        header[i++] = 0x80.toByte()
        header[i++] = 0x80.toByte()
        header[i++] = 0x05

        val prefix = 0x2
        header[i++] = ((prefix shl 4) or ((pts90 shr 29).toInt() and 0x0E) or 1).toByte()
        header[i++] = ((pts90 shr 22) and 0xFF).toByte()
        header[i++] = (((pts90 shr 14) and 0xFE) or 1).toByte()
        header[i++] = ((pts90 shr 7) and 0xFF).toByte()
        header[i++] = (((pts90 shl 1) and 0xFE) or 1).toByte()

        return header
    }

    // ---- TS packet writing --------------------------------------------------

    private fun writeSingleTsPacket(pid: Int, payload: ByteArray) {
        val pkt = ByteArray(TS_PACKET_SIZE)
        pkt[0] = SYNC_BYTE
        pkt[1] = (0x40 or (pid shr 8)).toByte() // PUSI=1
        pkt[2] = (pid and 0xFF).toByte()

        val counter = cc[pid]
        cc[pid] = (counter + 1) and 0x0F

        val available = TS_PACKET_SIZE - 4
        if (payload.size < available) {
            val stuffLen = available - payload.size - 2
            if (stuffLen >= 0) {
                pkt[3] = (0x30 or counter).toByte()
                pkt[4] = (1 + stuffLen).toByte()
                pkt[5] = 0x00
                for (j in 0 until stuffLen) pkt[6 + j] = 0xFF.toByte()
                payload.copyInto(pkt, 6 + stuffLen)
            } else {
                pkt[3] = (0x30 or counter).toByte()
                pkt[4] = 0x00
                payload.copyInto(pkt, 5)
            }
        } else {
            pkt[3] = (0x10 or counter).toByte()
            payload.copyInto(pkt, 4, 0, available)
        }

        out?.write(pkt)
    }

    private fun writePesPayload(
        pid: Int,
        payload: ByteArray,
        includePcr: Boolean,
        pcr90: Long,
        isKeyframe: Boolean,
    ) {
        var offset = 0
        var first = true

        while (offset < payload.size) {
            val pkt = ByteArray(TS_PACKET_SIZE)
            pkt[0] = SYNC_BYTE

            val counter = cc[pid]
            cc[pid] = (counter + 1) and 0x0F

            var headerLen = 4
            var adaptLen = 0
            var adaptStart = 4

            val needAdapt = (first && includePcr) || (first && isKeyframe)

            if (first) {
                pkt[1] = (0x40 or (pid shr 8)).toByte() // PUSI=1
            } else {
                pkt[1] = ((pid shr 8) and 0x1F).toByte()
            }
            pkt[2] = (pid and 0xFF).toByte()

            if (needAdapt) {
                pkt[3] = (0x30 or counter).toByte()
                adaptStart = 4
                var flags = 0
                var adaptDataLen = 0

                if (includePcr) {
                    flags = flags or 0x10
                    adaptDataLen += 6
                }
                if (isKeyframe) {
                    flags = flags or 0x40
                }

                pkt[5] = flags.toByte()
                var pos = 6

                if (includePcr) {
                    val pcrBase = pcr90
                    val pcrExt = 0L
                    pkt[pos++] = (pcrBase shr 25).toByte()
                    pkt[pos++] = (pcrBase shr 17).toByte()
                    pkt[pos++] = (pcrBase shr 9).toByte()
                    pkt[pos++] = (pcrBase shr 1).toByte()
                    pkt[pos++] = (((pcrBase and 1) shl 7) or 0x7E or ((pcrExt shr 8) and 1)).toByte()
                    pkt[pos++] = (pcrExt and 0xFF).toByte()
                }

                adaptLen = 1 + adaptDataLen
                pkt[4] = adaptLen.toByte()
                headerLen = 4 + 1 + adaptLen
            } else {
                pkt[3] = (0x10 or counter).toByte()
            }

            val space = TS_PACKET_SIZE - headerLen
            val remaining = payload.size - offset
            val toWrite = minOf(space, remaining)

            if (toWrite < space) {
                val stuffNeeded = space - toWrite
                if (!needAdapt) {
                    pkt[3] = (0x30 or counter).toByte()
                    if (stuffNeeded == 1) {
                        pkt[4] = 0x00
                        payload.copyInto(pkt, 5, offset, offset + toWrite)
                    } else {
                        pkt[4] = (stuffNeeded - 1).toByte()
                        pkt[5] = 0x00
                        for (j in 0 until stuffNeeded - 2) pkt[6 + j] = 0xFF.toByte()
                        payload.copyInto(pkt, 4 + stuffNeeded, offset, offset + toWrite)
                    }
                } else {
                    val currentAdaptLen = pkt[4].toInt() and 0xFF
                    val newAdaptLen = currentAdaptLen + stuffNeeded
                    pkt[4] = newAdaptLen.toByte()
                    val stuffStart = 5 + currentAdaptLen
                    for (j in 0 until stuffNeeded) pkt[stuffStart + j] = 0xFF.toByte()
                    payload.copyInto(pkt, 5 + newAdaptLen, offset, offset + toWrite)
                }
            } else {
                payload.copyInto(pkt, headerLen, offset, offset + toWrite)
            }

            out?.write(pkt)
            offset += toWrite
            first = false
        }
    }

    // ---- CRC32 (MPEG-2) -----------------------------------------------------

    companion object {
        private const val TS_PACKET_SIZE = 188
        private const val SYNC_BYTE: Byte = 0x47
        private const val PID_PAT = 0x0000
        private const val PID_PMT = 0x1000
        private const val PID_VIDEO = 0x0100
        private const val PID_AUDIO = 0x0101

        private val crcTable = IntArray(256).also { table ->
            for (i in 0 until 256) {
                var crc = i shl 24
                for (bit in 0 until 8) {
                    crc = if (crc and 0x80000000.toInt() != 0) {
                        (crc shl 1) xor 0x04C11DB7
                    } else {
                        crc shl 1
                    }
                }
                table[i] = crc
            }
        }

        fun crc32(data: ByteArray, offset: Int, length: Int): Int {
            var crc = -1 // 0xFFFFFFFF
            for (i in offset until offset + length) {
                val idx = ((crc shr 24) xor (data[i].toInt() and 0xFF)) and 0xFF
                crc = (crc shl 8) xor crcTable[idx]
            }
            return crc
        }
    }
}
