import Foundation
import Flutter
import NetworkExtension

/**
 * Native iOS bridge communicating Wi-Fi status and associated network metadata.
 * Reflects platform restrictions: iOS sandboxes indiscriminate BSSID scanning.
 */
public class WifiCapabilityBridge: NSObject {
    private let methodChannel: FlutterMethodChannel

    public init(messenger: FlutterBinaryMessenger) {
        self.methodChannel = FlutterMethodChannel(name: "com.wallahi.app/wifi_capability", binaryMessenger: messenger)
        super.init()
        self.methodChannel.setMethodCallHandler(self.handle)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformCapabilities":
            result([
                "platform": "iOS",
                "promiscuousScanSupported": false,
                "currentAssociationSupported": true,
                "restrictionNotice": "iOS sandboxes raw BSSID scanning. Connected AP metadata is read via NetworkExtension."
            ])
        case "fetchCurrentNetwork":
            if #available(iOS 14.0, *) {
                NEHotspotNetwork.fetchCurrent { currentNetwork in
                    if let network = currentNetwork {
                        result([
                            "ssid": network.ssid,
                            "bssid": network.bssid,
                            "signalStrength": network.signalStrength,
                            "isSecure": network.isSecure
                        ])
                    } else {
                        result([
                            "ssid": "Unassociated / Restricted",
                            "bssid": "00:00:00:00:00:00",
                            "signalStrength": 0.0
                        ])
                    }
                }
            } else {
                result(FlutterError(code: "UNSUPPORTED_VERSION", message: "iOS 14+ required", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
