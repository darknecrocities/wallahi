package com.wallahi.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Main Android activity registering ARCore, Wi-Fi RSSI, and Wi-Fi RTT native channels.
 */
class MainActivity : FlutterActivity() {
    private var arCoreBridge: ArCoreBridge? = null
    private var wifiRssiBridge: WifiRssiBridge? = null
    private var wifiRttBridge: WifiRttBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        arCoreBridge = ArCoreBridge(this, messenger)
        wifiRssiBridge = WifiRssiBridge(this, messenger)
        wifiRttBridge = WifiRttBridge(this, messenger)
    }
}
