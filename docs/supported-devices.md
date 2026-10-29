# Supported Devices & Hardware Capability Matrix

Wallahi features a multi-tiered capability architecture with graceful runtime fallbacks.

---

## 1. Capability Tiers

| Capability Level | Minimum Hardware Requirements | Platform Support | Spatial / RF Features Enabled |
| :--- | :--- | :--- | :--- |
| **Tier 1 (Base MVP)** | Camera + Accelerometer/Gyro + Wi-Fi radio | Android 10+ (API 29), iOS 16+ | AR tracking, horizontal floor plane detection, 2.4/5GHz RSSI mapping, 2D floor plan, heatmap interpolation. |
| **Tier 2 (Depth & RTT)** | ARCore Depth API support + 802.11mc Wi-Fi RTT chip | Android 10+ (Selected Pixel, Samsung Galaxy) | Dense surface extraction, obstacle reconstruction, meter-accurate RTT multilateration, AP position estimation. |
| **Tier 3 (LiDAR & RoomPlan)** | Apple LiDAR Scanner (iPhone 12+ Pro, iPad Pro) | iOS 16+ | High-precision RoomPlan mesh generation, recognized furniture/doors/windows, associated network diagnostics. |

---

## 2. Android Hardware Matrix

### 2.1 Google Pixel Series
| Model | ARCore Support | Depth API | Wi-Fi RTT Support | Notes |
| :--- | :--- | :--- | :--- | :--- |
| Pixel 6 / 6 Pro | Yes | Dual-camera depth | Yes (802.11mc) | Full Tier 2 capability |
| Pixel 7 / 7 Pro | Yes | ToF / Dual-camera | Yes (802.11mc) | Full Tier 2 capability |
| Pixel 8 / 8 Pro / 9 | Yes | Hardware depth | Yes (802.11mc/az) | Full Tier 2 capability |

### 2.2 Samsung Galaxy Series
| Model | ARCore Support | Depth API | Wi-Fi RTT Support | Notes |
| :--- | :--- | :--- | :--- | :--- |
| Galaxy S21 / S22 / S23 / S24 | Yes | Stereo Depth | Yes (Selected models) | Full Tier 1/2 capability |
| Galaxy A-Series (A52+) | Yes | Software depth | Varying by carrier | Tier 1 baseline |

---

## 3. iOS Hardware & Restrictions

- **RoomPlan**: Supported on iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, 16 Pro, and iPad Pro with LiDAR scanner.
- **Wi-Fi Scanning Restrictions**: Apple iOS restricts raw promiscuous or unassociated BSSID scanning to protect user privacy. Wallahi gracefully adapts:
  - On iOS, Wallahi reads the current active network SSID/BSSID and signal metrics via `NetworkExtension` entitlement where granted.
  - Users can manually log signal checkpoints or import RF survey logs.

---

## 4. Runtime Capability Detection Strategy

Before initiating a scan session, the mobile app queries:
1. `ar_bridge.isSupported()`
2. `ar_bridge.hasDepthSupport()`
3. `wifi_bridge.hasRttSupport()`
4. `wifi_bridge.isScanThrottled()`

If any hardware capability is absent, the UI shows a clear capability badge and switches to the appropriate fallback pipeline without interrupting the user workflow.
