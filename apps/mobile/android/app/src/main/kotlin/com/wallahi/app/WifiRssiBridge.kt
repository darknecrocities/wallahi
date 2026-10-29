package com.wallahi.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Native Android bridge communicating with WifiManager for RSSI scans.
 * Streams detected access points, frequencies, and signal strengths.
 */
class WifiRssiBridge(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val methodChannel = MethodChannel(messenger, "com.wallahi.app/wifi_rssi")
    private val scanEventChannel = EventChannel(messenger, "com.wallahi.app/wifi_scans")
    private val wifiManager =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

    private var scanEventSink: EventChannel.EventSink? = null
    private var isReceiverRegistered = false

    private val wifiScanReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context?, intent: Intent?) {
            val success = intent?.getBooleanExtra(WifiManager.EXTRA_RESULTS_UPDATED, false) ?: false
            if (success) {
                dispatchScanResults()
            }
        }
    }

    init {
        methodChannel.setMethodCallHandler(this)
        scanEventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "triggerScan" -> {
                val started = wifiManager?.startScan() ?: false
                result.success(started)
            }
            "isWifiEnabled" -> {
                result.success(wifiManager?.isWifiEnabled ?: false)
            }
            else -> result.notImplemented()
        }
    }

    private fun dispatchScanResults() {
        val scanResults: List<ScanResult>? = try {
            wifiManager?.scanResults
        } catch (e: SecurityException) {
            null
        }

        if (scanResults != null && scanEventSink != null) {
            val payload = scanResults.map { sr ->
                mapOf(
                    "bssid" to (sr.BSSID ?: "unknown"),
                    "ssid" to (sr.SSID ?: "Hidden"),
                    "rssiDbm" to sr.level,
                    "frequencyMhz" to sr.frequency,
                    "timestampMs" to System.currentTimeMillis()
                )
            }
            scanEventSink?.success(payload)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        scanEventSink = events
        if (!isReceiverRegistered) {
            val filter = IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
            context.registerReceiver(wifiScanReceiver, filter)
            isReceiverRegistered = true
        }
    }

    override fun onCancel(arguments: Any?) {
        scanEventSink = null
        if (isReceiverRegistered) {
            try {
                context.unregisterReceiver(wifiScanReceiver)
            } catch (_: Exception) {}
            isReceiverRegistered = false
        }
    }
}
