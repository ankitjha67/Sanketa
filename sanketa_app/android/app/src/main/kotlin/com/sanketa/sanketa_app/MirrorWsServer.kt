package com.sanketa.sanketa_app

import android.util.Base64
import android.util.Log
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.net.ServerSocket
import java.net.Socket
import java.nio.ByteBuffer
import java.security.MessageDigest
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean

class MirrorWsServer {

    private var serverSocket: ServerSocket? = null
    private val clients = CopyOnWriteArrayList<ClientConn>()
    private val running = AtomicBoolean(false)
    private var acceptThread: Thread? = null

    val port: Int get() = serverSocket?.localPort ?: 0
    val clientCount: Int get() = clients.size

    fun start(): Int {
        stop()
        val ss = ServerSocket(0, 5)
        serverSocket = ss
        running.set(true)

        acceptThread = Thread({
            while (running.get()) {
                try {
                    val socket = ss.accept()
                    handleNewConnection(socket)
                } catch (_: IOException) {
                    if (running.get()) Log.w(TAG, "Accept failed")
                }
            }
        }, "MirrorWsAccept").also { it.isDaemon = true; it.start() }

        Log.i(TAG, "WebSocket server started on port ${ss.localPort}")
        return ss.localPort
    }

    fun stop() {
        running.set(false)
        clients.forEach { it.close() }
        clients.clear()
        try { serverSocket?.close() } catch (_: IOException) {}
        serverSocket = null
        acceptThread?.interrupt()
        acceptThread = null
    }

    fun broadcast(data: ByteArray) {
        val frame = buildBinaryFrame(data)
        val dead = mutableListOf<ClientConn>()
        for (c in clients) {
            try {
                c.send(frame)
            } catch (_: IOException) {
                dead.add(c)
            }
        }
        dead.forEach { removeClient(it) }
    }

    fun sendConfig(width: Int, height: Int, fps: Int, sampleRate: Int, channels: Int) {
        val json = """{"w":$width,"h":$height,"fps":$fps,"sr":$sampleRate,"ch":$channels}"""
        val payload = ByteArray(5 + json.length)
        payload[0] = TYPE_CONFIG
        // timestamp 0 for config
        json.toByteArray(Charsets.UTF_8).copyInto(payload, 5)
        broadcast(payload)
    }

    fun sendVideoFrame(nalData: ByteArray, timestampMs: Long, isKeyframe: Boolean) {
        val type = if (isKeyframe) TYPE_VIDEO_KEY else TYPE_VIDEO_DELTA
        val payload = ByteArray(5 + nalData.size)
        payload[0] = type
        putTimestamp(payload, 1, timestampMs)
        nalData.copyInto(payload, 5)
        broadcast(payload)
    }

    fun sendAudioFrame(aacData: ByteArray, timestampMs: Long) {
        val payload = ByteArray(5 + aacData.size)
        payload[0] = TYPE_AUDIO
        putTimestamp(payload, 1, timestampMs)
        aacData.copyInto(payload, 5)
        broadcast(payload)
    }

    private fun putTimestamp(buf: ByteArray, offset: Int, ms: Long) {
        val ts = (ms and 0xFFFFFFFFL).toInt()
        buf[offset] = (ts shr 24).toByte()
        buf[offset + 1] = (ts shr 16).toByte()
        buf[offset + 2] = (ts shr 8).toByte()
        buf[offset + 3] = ts.toByte()
    }

    private fun handleNewConnection(socket: Socket) {
        Thread({
            try {
                socket.tcpNoDelay = true
                val input = socket.getInputStream()
                val output = socket.getOutputStream()

                if (!performHandshake(input, output)) {
                    socket.close()
                    return@Thread
                }

                val conn = ClientConn(socket, output)
                clients.add(conn)
                Log.i(TAG, "Client connected (${clients.size} total)")

                readLoop(conn, input)
            } catch (_: IOException) {
            } finally {
                try { socket.close() } catch (_: IOException) {}
            }
        }, "MirrorWsClient").also { it.isDaemon = true; it.start() }
    }

    private fun performHandshake(input: InputStream, output: OutputStream): Boolean {
        val request = StringBuilder()
        var prev = 0
        while (true) {
            val b = input.read()
            if (b == -1) return false
            request.append(b.toChar())
            if (prev == '\n'.code && b == '\r'.code) {
                val next = input.read()
                if (next == '\n'.code) break
                if (next == -1) return false
                request.append(next.toChar())
            }
            prev = b
        }

        val keyLine = request.lines().find {
            it.startsWith("Sec-WebSocket-Key:", ignoreCase = true)
        } ?: return false

        val key = keyLine.substringAfter(":").trim()
        val accept = computeAcceptKey(key)

        val response = "HTTP/1.1 101 Switching Protocols\r\n" +
                "Upgrade: websocket\r\n" +
                "Connection: Upgrade\r\n" +
                "Sec-WebSocket-Accept: $accept\r\n" +
                "Access-Control-Allow-Origin: *\r\n" +
                "\r\n"
        output.write(response.toByteArray(Charsets.UTF_8))
        output.flush()
        return true
    }

    private fun computeAcceptKey(key: String): String {
        val combined = key + WS_GUID
        val sha1 = MessageDigest.getInstance("SHA-1").digest(combined.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(sha1, Base64.NO_WRAP)
    }

    // Read client frames: handle close and ping, discard everything else
    private fun readLoop(conn: ClientConn, input: InputStream) {
        try {
            while (running.get() && !conn.closed) {
                val b0 = input.read()
                if (b0 == -1) break
                val b1 = input.read()
                if (b1 == -1) break

                val opcode = b0 and 0x0F
                val masked = (b1 and 0x80) != 0
                var len = (b1 and 0x7F).toLong()

                if (len == 126L) {
                    val h = input.read()
                    val l = input.read()
                    if (h == -1 || l == -1) break
                    len = ((h shl 8) or l).toLong()
                } else if (len == 127L) {
                    var v = 0L
                    for (i in 0 until 8) {
                        val x = input.read()
                        if (x == -1) break
                        v = (v shl 8) or x.toLong()
                    }
                    len = v
                }

                val mask = if (masked) {
                    val m = ByteArray(4)
                    if (readFully(input, m) != 4) break
                    m
                } else null

                if (len > MAX_CLIENT_FRAME) {
                    break // oversized frame, disconnect
                }

                val payload = ByteArray(len.toInt())
                if (len > 0 && readFully(input, payload) != len.toInt()) break

                if (mask != null) {
                    for (i in payload.indices) {
                        payload[i] = (payload[i].toInt() xor mask[i % 4].toInt()).toByte()
                    }
                }

                when (opcode) {
                    0x08 -> break // close
                    0x09 -> { // ping → pong
                        try {
                            val pong = buildControlFrame(0x0A, payload)
                            conn.send(pong)
                        } catch (_: IOException) {
                            break
                        }
                    }
                }
            }
        } catch (_: IOException) {
        } finally {
            removeClient(conn)
            Log.i(TAG, "Client disconnected (${clients.size} remaining)")
        }
    }

    private fun removeClient(conn: ClientConn) {
        conn.close()
        clients.remove(conn)
    }

    private fun readFully(input: InputStream, buf: ByteArray): Int {
        var off = 0
        while (off < buf.size) {
            val n = input.read(buf, off, buf.size - off)
            if (n == -1) return off
            off += n
        }
        return off
    }

    private fun buildBinaryFrame(payload: ByteArray): ByteArray {
        val len = payload.size
        val header: ByteArray
        when {
            len <= 125 -> {
                header = ByteArray(2)
                header[0] = 0x82.toByte() // FIN + binary
                header[1] = len.toByte()
            }
            len <= 65535 -> {
                header = ByteArray(4)
                header[0] = 0x82.toByte()
                header[1] = 126.toByte()
                header[2] = (len shr 8).toByte()
                header[3] = (len and 0xFF).toByte()
            }
            else -> {
                header = ByteArray(10)
                header[0] = 0x82.toByte()
                header[1] = 127.toByte()
                val l = len.toLong()
                for (i in 0 until 8) {
                    header[2 + i] = (l shr (56 - i * 8)).toByte()
                }
            }
        }
        return header + payload
    }

    private fun buildControlFrame(opcode: Int, payload: ByteArray): ByteArray {
        val header = ByteArray(2)
        header[0] = (0x80 or opcode).toByte()
        header[1] = payload.size.toByte()
        return header + payload
    }

    private class ClientConn(
        private val socket: Socket,
        private val output: OutputStream
    ) {
        @Volatile var closed = false

        @Synchronized
        fun send(frame: ByteArray) {
            if (closed) return
            output.write(frame)
            output.flush()
        }

        fun close() {
            closed = true
            try { socket.close() } catch (_: IOException) {}
        }
    }

    companion object {
        private const val TAG = "MirrorWsServer"
        private const val WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        private const val MAX_CLIENT_FRAME = 65536L

        const val TYPE_VIDEO_KEY: Byte = 0x01
        const val TYPE_VIDEO_DELTA: Byte = 0x02
        const val TYPE_AUDIO: Byte = 0x03
        const val TYPE_CONFIG: Byte = 0x09
    }
}
