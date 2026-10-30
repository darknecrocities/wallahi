import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var roomCaptureBridge: RoomCaptureBridge?
    private var wifiCapabilityBridge: WifiCapabilityBridge?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        roomCaptureBridge = RoomCaptureBridge(messenger: controller.binaryMessenger)
        wifiCapabilityBridge = WifiCapabilityBridge(messenger: controller.binaryMessenger)

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
