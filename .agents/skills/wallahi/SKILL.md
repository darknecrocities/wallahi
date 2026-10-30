---
name: wallahi
description: Production domain skill for Wallahi indoor spatial mapping with computer vision and Wi-Fi sensor fusion.
---

# Wallahi: Computer Vision + Wi-Fi Indoor Spatial Mapping

## Architecture Invariants
- **Coordinate System**: Metric Cartesian ($+Y$ up, $XZ$ floor plane, right-handed).
- **Core Domain Packages**:
  - `packages/room_format`: Canonical JSON schema and portable data exchange.
  - `packages/geometry`: 2D/3D vector mathematics, ray-casting containment, and orthogonal wall snapping.
  - `packages/wifi_models`: Log-distance path loss, IDW/RBF interpolation, and RTT multilateration.
  - `packages/sensor_fusion`: Spatiotemporal pose association ($\le 100\text{ ms}$ window), grid binning, and uncertainty fields.
- **Mobile Application**:
  - Flutter frontend (`apps/mobile/lib`) with Riverpod state management.
  - Native Android bridges (`ArCoreBridge.kt`, `WifiRssiBridge.kt`, `WifiRttBridge.kt`).
  - Native iOS bridges (`RoomCaptureBridge.swift`, `WifiCapabilityBridge.swift`).
- **Processing & Evaluation Pipeline**:
  - `processing/floorplan/regularizer.py`: Orthogonal wall alignment ($90^\circ / 180^\circ$) and loop closure.
  - `processing/open3d/pointcloud_processor.py`: Statistical Outlier Removal and RANSAC plane fitting.
  - `processing/evaluation/benchmark_evaluator.py`: WDE, LCE, and RF holdout cross-validation RMSE.
  - `backend/app/main.py`: Optional FastAPI microservice.

## Verification Protocol
Before release, verify:
1. `python3 /Users/arronkianparejas/SkillBuilder/skills/world-class-engineering/scripts/check_source_line_limits.py --path . --show-tiers`
2. `(cd packages/room_format && dart test) && (cd packages/geometry && dart test) && (cd packages/wifi_models && dart test) && (cd packages/sensor_fusion && dart test)`
3. `(cd apps/mobile && flutter test)`
4. `python3 -m unittest discover -s . -p "test_*.py"`
5. `python3 /Users/arronkianparejas/SkillBuilder/skills/full-scale-mode/scripts/orchestration_harness.py --path .`
