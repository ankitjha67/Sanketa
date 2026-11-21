package com.sanketa.sanketa_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.view.Surface
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

class ScreenMirrorService : Service() {

    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var encoder: MediaCodec? = null
    private var inputSurface: Surface? = null
    private var encoderThread: HandlerThread? = null
    private var encoderHandler: Handler? = null
    private lateinit var segmentDir: File
    private var segmentIndex = 0
    private var tsMuxer: TsMuxer? = null
    private val running = AtomicBoolean(false)
    private var captureWidth = 720
    private var captureHeight = 1280

    private var audioRecord: AudioRecord? = null
    private var audioEncoder: MediaCodec? = null
    private var audioThread: HandlerThread? = null
    private var audioHandler: Handler? = null
    private var audioInputThread: Thread? = null

    private var wsServer: MirrorWsServer? = null
    private var mode: String = "hls"

    private var spsData: ByteArray? = null
    private var ppsData: ByteArray? = null

    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            stopSelf()
        }
    }

    private val projectionCallback = object : MediaProjection.Callback() {
        override fun onStop() {
            stopSelf()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
        val data: Intent? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(EXTRA_DATA)
        }
        if (data == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        captureWidth = intent.getIntExtra(EXTRA_WIDTH, 720)
        captureHeight = intent.getIntExtra(EXTRA_HEIGHT, 1280)
        val dpi = intent.getIntExtra(EXTRA_DPI, 1)
        val dirPath = intent.getStringExtra(EXTRA_SEGMENT_DIR)
        segmentDir = if (dirPath != null) File(dirPath) else File(cacheDir, "screen_mirror")
        segmentDir.mkdirs()
        mode = intent.getStringExtra(EXTRA_MODE) ?: "hls"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        val filter = IntentFilter(ACTION_STOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopReceiver, filter)
        }

        val projectionManager =
            getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        projection = projectionManager.getMediaProjection(resultCode, data)
        if (projection == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        projection?.registerCallback(projectionCallback, null)

        if (mode == "ws") {
            wsServer = MirrorWsServer().also { it.start() }
            lastWsPort = wsServer?.port ?: 0
        }

        startEncoding(dpi)
        startAudioCapture()

        return START_NOT_STICKY
    }

    private fun startEncoding(dpi: Int) {
        running.set(true)
        segmentIndex = 0

        val format = MediaFormat.createVideoFormat(
            MediaFormat.MIMETYPE_VIDEO_AVC, captureWidth, captureHeight
        ).apply {
            setInteger(
                MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
            )
            setInteger(MediaFormat.KEY_BIT_RATE, 2_500_000)
            setInteger(MediaFormat.KEY_FRAME_RATE, 30)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
        }

        encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC).also { codec ->
            codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            inputSurface = codec.createInputSurface()
        }

        virtualDisplay = projection?.createVirtualDisplay(
            "SanketaScreenMirror",
            captureWidth, captureHeight, dpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            inputSurface, null, null
        )

        encoderThread = HandlerThread("SanketaEncoder").also { it.start() }
        encoderHandler = Handler(encoderThread!!.looper)

        encoder!!.start()
        encoderHandler!!.post { drainEncoder() }
    }

    @Suppress("MissingPermission")
    private fun startAudioCapture() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        val proj = projection ?: return

        try {
            val captureConfig = AudioPlaybackCaptureConfiguration.Builder(proj)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                .build()

            val audioFormat = AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(AUDIO_SAMPLE_RATE)
                .setChannelMask(AudioFormat.CHANNEL_IN_STEREO)
                .build()

            val bufSize = AudioRecord.getMinBufferSize(
                AUDIO_SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_STEREO,
                AudioFormat.ENCODING_PCM_16BIT
            ).coerceAtLeast(4096)

            audioRecord = AudioRecord.Builder()
                .setAudioPlaybackCaptureConfig(captureConfig)
                .setAudioFormat(audioFormat)
                .setBufferSizeInBytes(bufSize)
                .build()

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                audioRecord?.release()
                audioRecord = null
                return
            }

            val aacFormat = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC, AUDIO_SAMPLE_RATE, AUDIO_CHANNELS
            ).apply {
                setInteger(MediaFormat.KEY_BIT_RATE, AUDIO_BIT_RATE)
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, bufSize)
            }

            audioEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC).also {
                it.configure(aacFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            }

            audioThread = HandlerThread("SanketaAudioEncoder").also { it.start() }
            audioHandler = Handler(audioThread!!.looper)

            audioEncoder!!.start()
            audioRecord!!.startRecording()

            audioInputThread = Thread({
                feedAudioEncoder()
            }, "SanketaAudioInput").also { it.start() }

            audioHandler!!.post { drainAudioEncoder() }

            wsServer?.sendConfig(captureWidth, captureHeight, 30, AUDIO_SAMPLE_RATE, AUDIO_CHANNELS)
        } catch (_: SecurityException) {
            // RECORD_AUDIO not granted — video-only mirroring
            cleanupAudio()
        } catch (_: Exception) {
            cleanupAudio()
        }
    }

    private fun feedAudioEncoder() {
        val record = audioRecord ?: return
        val codec = audioEncoder ?: return
        val pcmBuf = ByteArray(4096)

        while (running.get()) {
            val read = record.read(pcmBuf, 0, pcmBuf.size)
            if (read <= 0) continue

            val inIdx = try {
                codec.dequeueInputBuffer(10_000)
            } catch (_: IllegalStateException) {
                break
            }
            if (inIdx < 0) continue

            val inputBuf = codec.getInputBuffer(inIdx) ?: continue
            inputBuf.clear()
            inputBuf.put(pcmBuf, 0, read)
            codec.queueInputBuffer(inIdx, 0, read, System.nanoTime() / 1000, 0)
        }
    }

    private fun drainAudioEncoder() {
        val codec = audioEncoder ?: return
        val bufferInfo = MediaCodec.BufferInfo()

        while (running.get()) {
            val index = try {
                codec.dequeueOutputBuffer(bufferInfo, 10_000)
            } catch (_: IllegalStateException) {
                break
            }

            if (index >= 0) {
                if (bufferInfo.size > 0 &&
                    (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG) == 0
                ) {
                    val buf = codec.getOutputBuffer(index)
                    if (buf != null) {
                        buf.position(bufferInfo.offset)
                        buf.limit(bufferInfo.offset + bufferInfo.size)
                        val aacData = ByteArray(bufferInfo.size)
                        buf.get(aacData)

                        val adts = buildAdtsHeader(aacData.size)
                        val adtsFrame = ByteArray(adts.size + aacData.size)
                        System.arraycopy(adts, 0, adtsFrame, 0, adts.size)
                        System.arraycopy(aacData, 0, adtsFrame, adts.size, aacData.size)

                        tsMuxer?.writeAudioFrame(adtsFrame, bufferInfo.presentationTimeUs)

                        if (mode == "ws") {
                            wsServer?.sendAudioFrame(adtsFrame, bufferInfo.presentationTimeUs / 1000)
                        }
                    }
                }
                codec.releaseOutputBuffer(index, false)

                if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) break
            }
        }
    }

    private fun buildAdtsHeader(frameLength: Int): ByteArray {
        val packetLen = 7 + frameLength
        val header = ByteArray(7)
        // syncword 0xFFF, id=0 (MPEG-4), layer=0, protection_absent=1
        header[0] = 0xFF.toByte()
        header[1] = 0xF1.toByte()
        // profile=1 (AAC-LC), sampling_freq_index=4 (44100), private=0, channel_config=2
        header[2] = ((1 shl 6) or (4 shl 2) or (0 shl 1) or (2 ushr 2)).toByte()
        header[3] = (((2 and 3) shl 6) or (0 shl 5) or (0 shl 4) or ((packetLen ushr 11) and 0x03)).toByte()
        header[4] = ((packetLen ushr 3) and 0xFF).toByte()
        header[5] = (((packetLen and 0x07) shl 5) or 0x1F).toByte()
        header[6] = 0xFC.toByte()
        return header
    }

    private fun drainEncoder() {
        val codec = encoder ?: return
        val bufferInfo = MediaCodec.BufferInfo()
        var segmentHasFrames = false

        while (running.get()) {
            val index = try {
                codec.dequeueOutputBuffer(bufferInfo, 10_000)
            } catch (_: IllegalStateException) {
                break
            }
            when {
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val newFormat = codec.outputFormat
                    val spsBuf = newFormat.getByteBuffer("csd-0")
                    val ppsBuf = newFormat.getByteBuffer("csd-1")
                    spsData = spsBuf?.let { b ->
                        ByteArray(b.remaining()).also { b.get(it) }
                    }
                    ppsData = ppsBuf?.let { b ->
                        ByteArray(b.remaining()).also { b.get(it) }
                    }
                    tsMuxer = TsMuxer(spsData, ppsData)
                }

                index >= 0 -> {
                    if (bufferInfo.size > 0) {
                        val buf = codec.getOutputBuffer(index) ?: continue
                        buf.position(bufferInfo.offset)
                        buf.limit(bufferInfo.offset + bufferInfo.size)

                        val isKeyFrame =
                            (bufferInfo.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0

                        if (isKeyFrame && tsMuxer != null) {
                            if (segmentHasFrames) {
                                openNewSegment()
                            } else if (tsMuxer?.isSegmentOpen != true) {
                                openNewSegment()
                            }
                            segmentHasFrames = false
                        }

                        val data = ByteArray(bufferInfo.size)
                        buf.get(data)

                        tsMuxer?.writeVideoFrame(
                            data, bufferInfo.presentationTimeUs, isKeyFrame
                        )
                        segmentHasFrames = true

                        if (mode == "ws") {
                            val tsMs = bufferInfo.presentationTimeUs / 1000
                            val nalData = if (isKeyFrame && spsData != null && ppsData != null) {
                                ByteArray(spsData!!.size + ppsData!!.size + data.size).also {
                                    spsData!!.copyInto(it)
                                    ppsData!!.copyInto(it, spsData!!.size)
                                    data.copyInto(it, spsData!!.size + ppsData!!.size)
                                }
                            } else data
                            wsServer?.sendVideoFrame(nalData, tsMs, isKeyFrame)
                        }
                    }
                    codec.releaseOutputBuffer(index, false)

                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        running.set(false)
                    }
                }
            }
        }
    }

    private fun openNewSegment() {
        tsMuxer?.endSegment()

        val name = "seg_%06d.ts".format(segmentIndex)
        val file = File(segmentDir, name)
        tsMuxer?.resetContinuityCounters()
        tsMuxer?.startSegment(file)

        File(segmentDir, "latest.txt").writeText(segmentIndex.toString())
        segmentIndex++

        pruneOldSegments()
    }

    private fun pruneOldSegments() {
        val keep = 20
        val oldest = segmentIndex - keep - 1
        if (oldest >= 0) {
            val old = File(segmentDir, "seg_%06d.ts".format(oldest))
            old.delete()
        }
    }

    private fun cleanupAudio() {
        try { audioRecord?.stop() } catch (_: Exception) {}
        try { audioRecord?.release() } catch (_: Exception) {}
        audioRecord = null

        try { audioEncoder?.stop() } catch (_: Exception) {}
        try { audioEncoder?.release() } catch (_: Exception) {}
        audioEncoder = null

        audioInputThread?.interrupt()
        audioInputThread = null

        audioThread?.quitSafely()
        audioThread = null
        audioHandler = null
    }

    private fun stopEncoding() {
        running.set(false)

        try {
            encoder?.signalEndOfInputStream()
        } catch (_: Exception) {}

        audioInputThread?.interrupt()
        audioInputThread?.join(1_000)
        audioInputThread = null

        cleanupAudio()

        encoderThread?.quitSafely()
        encoderThread?.join(2_000)
        encoderThread = null
        encoderHandler = null

        virtualDisplay?.release()
        virtualDisplay = null

        try {
            encoder?.stop()
        } catch (_: Exception) {}
        try {
            encoder?.release()
        } catch (_: Exception) {}
        encoder = null
        inputSurface = null

        tsMuxer?.endSegment()

        wsServer?.stop()
        wsServer = null
        lastWsPort = 0
    }

    override fun onDestroy() {
        stopEncoding()
        projection?.unregisterCallback(projectionCallback)
        projection?.stop()
        projection = null
        try {
            unregisterReceiver(stopReceiver)
        } catch (_: Exception) {}
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "Screen Mirroring",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Active while mirroring screen to TV"
        }
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification {
        val stopIntent = Intent(ACTION_STOP)
        val stopPending = PendingIntent.getBroadcast(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("Screen Mirroring")
            .setContentText("Your screen is being cast to TV")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .addAction(
                Notification.Action.Builder(
                    null, "Stop Mirroring", stopPending
                ).build()
            )
            .setOngoing(true)
            .build()
    }

    companion object {
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_DATA = "data"
        const val EXTRA_WIDTH = "width"
        const val EXTRA_HEIGHT = "height"
        const val EXTRA_DPI = "dpi"
        const val EXTRA_SEGMENT_DIR = "segmentDir"
        const val EXTRA_MODE = "mode"
        const val ACTION_STOP = "com.sanketa.STOP_MIRROR"
        private const val CHANNEL_ID = "screen_mirror"
        private const val NOTIFICATION_ID = 9001

        private const val AUDIO_SAMPLE_RATE = 44100
        private const val AUDIO_CHANNELS = 2
        private const val AUDIO_BIT_RATE = 128_000

        @Volatile
        var lastWsPort: Int = 0

        fun start(
            context: Context, resultCode: Int, data: Intent,
            width: Int, height: Int, dpi: Int, segmentDir: String,
            mode: String = "hls"
        ) {
            val intent = Intent(context, ScreenMirrorService::class.java).apply {
                putExtra(EXTRA_RESULT_CODE, resultCode)
                putExtra(EXTRA_DATA, data)
                putExtra(EXTRA_WIDTH, width)
                putExtra(EXTRA_HEIGHT, height)
                putExtra(EXTRA_DPI, dpi)
                putExtra(EXTRA_SEGMENT_DIR, segmentDir)
                putExtra(EXTRA_MODE, mode)
            }
            context.startForegroundService(intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ScreenMirrorService::class.java))
        }
    }
}
