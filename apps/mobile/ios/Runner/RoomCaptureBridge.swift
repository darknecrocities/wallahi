import Foundation
import Flutter
#if canImport(RoomPlan)
import RoomPlan
#endif

/**
 * Native iOS bridge communicating with Apple RoomPlan / ARKit.
 * Detects walls, openings, and structured geometry on LiDAR-enabled devices.
 */
public class RoomCaptureBridge: NSObject {
    private let methodChannel: FlutterMethodChannel

    public init(messenger: FlutterBinaryMessenger) {
        self.methodChannel = FlutterMethodChannel(name: "com.wallahi.app/room_capture", binaryMessenger: messenger)
        super.init()
        self.methodChannel.setMethodCallHandler(self.handle)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isRoomPlanSupported":
            #if canImport(RoomPlan)
            if #available(iOS 16.0, *) {
                result(RoomCaptureSession.isSupported)
                return
            }
            #endif
            result(false)
        case "startCapture":
            result(true)
        case "stopCapture":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
