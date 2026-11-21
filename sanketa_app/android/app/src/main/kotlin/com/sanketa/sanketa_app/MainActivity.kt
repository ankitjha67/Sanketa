package com.sanketa.sanketa_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.ConsumerIrManager
import android.media.projection.MediaProjectionManager
import android.net.wifi.WifiManager
import android.provider.Settings
import android.util.DisplayMetrics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private val consumerIrManager: ConsumerIrManager? by lazy {
        getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager
    }

    private var mirrorPermissionResult: MethodChannel.Result? = null
    private var pendingProjectionResultCode: Int? = null
    private var pendingProjectionData: Intent? = null

    companion object {
        private const val MIRROR_REQUEST_CODE = 9001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.sanketa/multicast")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquire" -> {
                        acquireMulticastLock()
                        result.success(true)
                    }
                    "release" -> {
                        releaseMulticastLock()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.sanketa/ir")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasIrEmitter" -> result.success(
                        consumerIrManager?.hasIrEmitter() == true
                    )
                    "carrierFrequencies" -> {
                        val frequencies = consumerIrManager
                            ?.carrierFrequencies
                            ?.map { range -> (range.minFrequency + range.maxFrequency) / 2 }
                            ?: emptyList()
                        result.success(frequencies)
                    }
                    "transmit" -> transmitIr(call.argument("frequencyHz"), call.argument("pattern"), result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.sanketa/screen_mirror")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        mirrorPermissionResult = result
                        val pm = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        startActivityForResult(pm.createScreenCaptureIntent(), MIRROR_REQUEST_CODE)
                    }
                    "startMirror" -> {
                        val width = call.argument<Int>("width") ?: 720
                        val height = call.argument<Int>("height") ?: 1280
                        val dpi = call.argument<Int>("dpi") ?: 1
                        val mode = call.argument<String>("mode") ?: "hls"
                        val segmentDir = call.argument<String>("segmentDir")
                            ?: "${cacheDir.absolutePath}/screen_mirror"
                        val projResultCode = pendingProjectionResultCode
                        val projData = pendingProjectionData

                        if (projResultCode == null || projData == null) {
                            result.error("missing_permission", "Call requestPermission first", null)
                            return@setMethodCallHandler
                        }

                        ScreenMirrorService.start(
                            this, projResultCode, projData, width, height, dpi, segmentDir, mode
                        )

                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                            val wsPort = ScreenMirrorService.lastWsPort
                            android.util.Log.i("SanketaMirror", "Returning to Flutter: segmentDir=$segmentDir wsPort=$wsPort mode=$mode")
                            result.success(mapOf(
                                "segmentDir" to segmentDir,
                                "wsPort" to if (wsPort > 0) wsPort else null,
                            ))
                        }, 500)
                    }
                    "openMiracast" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_CAST_SETTINGS))
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "stopMirror" -> {
                        ScreenMirrorService.stop(this)
                        pendingProjectionResultCode = null
                        pendingProjectionData = null
                        result.success(null)
                    }
                    "isActive" -> {
                        result.success(false)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun transmitIr(
        frequencyHz: Int?,
        pattern: List<Int>?,
        result: MethodChannel.Result,
    ) {
        val manager = consumerIrManager
        if (manager?.hasIrEmitter() != true) {
            result.error("ir_unavailable", "This device has no IR emitter", null)
            return
        }
        if (frequencyHz == null || frequencyHz <= 0 || pattern.isNullOrEmpty() || pattern.any { it <= 0 }) {
            result.error("invalid_ir_signal", "Frequency and pattern must contain positive values", null)
            return
        }

        try {
            manager.transmit(frequencyHz, pattern.toIntArray())
            result.success(null)
        } catch (error: SecurityException) {
            result.error("ir_permission_denied", error.message, null)
        } catch (error: IllegalArgumentException) {
            result.error("invalid_ir_signal", error.message, null)
        } catch (error: RuntimeException) {
            result.error("ir_transmit_failed", error.message, null)
        }
    }

    private fun acquireMulticastLock() {
        if (multicastLock?.isHeld == true) return
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        multicastLock = wifi.createMulticastLock("sanketa_discovery").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseMulticastLock() {
        multicastLock?.let {
            if (it.isHeld) it.release()
        }
        multicastLock = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == MIRROR_REQUEST_CODE) {
            val pending = mirrorPermissionResult
            mirrorPermissionResult = null
            if (resultCode == Activity.RESULT_OK && data != null) {
                pendingProjectionResultCode = resultCode
                pendingProjectionData = data
                pending?.success(mapOf(
                    "resultCode" to resultCode,
                    "dataUri" to "stored",
                ))
            } else {
                pending?.error("permission_denied", "User denied screen capture", null)
            }
        }
    }

    override fun onDestroy() {
        releaseMulticastLock()
        super.onDestroy()
    }
}
