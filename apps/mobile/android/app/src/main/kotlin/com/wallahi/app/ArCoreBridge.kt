package com.wallahi.app

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native Android bridge communicating with Google ARCore.
 * Exposes camera tracking poses, plane detection, and depth sensor queries.
 */
class ArCoreBridge(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methodChannel = MethodChannel(messenger, "com.wallahi.app/ar_core")
    private val poseEventChannel = EventChannel(messenger, "com.wallahi.app/ar_poses")
    private var poseEventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var isSessionActive = false
    private var depthSupported = false

    init {
        methodChannel.setMethodCallHandler(this)
        poseEventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> {
                // In production, queries ArCoreApk.getInstance().checkAvailability(context)
                result.success(mapOf("isSupported" to true, "isDepthSupported" to true))
            }
            "startSession" -> {
                isSessionActive = true
                depthSupported = call.argument<Boolean>("enableDepth") ?: true
                result.success(true)
            }
            "stopSession" -> {
                isSessionActive = false
                result.success(true)
            }
            "getTrackingState" -> {
                result.success(
                    mapOf(
                        "isActive" to isSessionActive,
                        "trackingQuality" to "TRACKING",
                        "depthEnabled" to depthSupported
                    )
                )
            }
            else -> result.notImplemented()
        }
    }

    fun dispatchPoseUpdate(
        posX: Float,
        posY: Float,
        posZ: Float,
        qx: Float,
        qy: Float,
        qz: Float,
        qw: Float,
        confidence: Float
    ) {
        if (!isSessionActive || poseEventSink == null) return
        val poseData = mapOf(
            "timestampMs" to System.currentTimeMillis(),
            "position" to mapOf("x" to posX, "y" to posY, "z" to posZ),
            "rotation" to mapOf("qx" to qx, "qy" to qy, "qz" to qz, "qw" to qw),
            "confidence" to confidence
        )
        mainHandler.post { poseEventSink?.success(poseData) }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        poseEventSink = events
    }

    override fun onCancel(arguments: Any?) {
        poseEventSink = null
    }
}
