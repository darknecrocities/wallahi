import 'package:geometry/geometry.dart';
import 'package:room_format/room_format.dart';
import 'package:sensor_fusion/sensor_fusion.dart';
import 'package:test/test.dart';
import 'package:wifi_models/wifi_models.dart';

void main() {
  group('Sensor Fusion Package Tests', () {
    test('PoseInterpolator interpolates trajectory poses in time', () {
      const interpolator = PoseInterpolator();
      final trajectory = [
        const ArPoseKeyframe(
          timestampMs: 1000,
          position: Vec3(0, 0, 0),
          rotation: (0, 0, 0, 1),
        ),
        const ArPoseKeyframe(
          timestampMs: 1200,
          position: Vec3(0.2, 0, 0),
          rotation: (0, 0, 0, 1),
        ),
      ];

      // Exact midpoint at 1100ms
      final result = interpolator.interpolatePose(1100, trajectory);
      expect(result, isNotNull);
      expect(result!.$1.x, closeTo(0.1, 0.001));
      expect(result.$1.y, closeTo(0.0, 0.001));
      expect(result.$2, greaterThan(0.8));
    });

    test('SpatialGridAggregator computes median RSSI across multiple samples', () {
      const aggregator = SpatialGridAggregator(cellSizeMeters: 1.0);
      final samples = [
        const SpatialRfSample(position: Vec2(0.2, 0.2), rssiDbm: -50.0),
        const SpatialRfSample(position: Vec2(0.3, 0.3), rssiDbm: -52.0),
        const SpatialRfSample(position: Vec2(0.4, 0.4), rssiDbm: -90.0), // outlier
      ];

      final aggregated = aggregator.aggregate(samples);
      expect(aggregated.length, equals(1));
      // Median of -90, -52, -50 is -52
      expect(aggregated.first.medianRssiDbm, equals(-52.0));
      expect(aggregated.first.sampleCount, equals(3));
    });

    test('UncertaintyEstimator detects unvisited room quadrants for rescan', () {
      const estimator = UncertaintyEstimator(rescanDistanceThresholdMeters: 2.0);
      final floorPolygon = [
        const Vec2(0, 0),
        const Vec2(6, 0),
        const Vec2(6, 6),
        const Vec2(0, 6),
      ];
      // Only visited near (1, 1)
      final sampleLocations = [
        const Vec2(1.0, 1.0),
        const Vec2(1.2, 1.1),
      ];

      final rescanRecs = estimator.detectRescanAreas(
        floorPolygon: floorPolygon,
        sampleLocations: sampleLocations,
        gridStepMeters: 1.0,
      );

      // Areas around (5, 5) should be detected as unvisited
      expect(rescanRecs, isNotEmpty);
      final farCorner = rescanRecs.any((r) => r.targetFloorPosition.x >= 4.0 && r.targetFloorPosition.z >= 4.0);
      expect(farCorner, isTrue);
    });

    test('SensorFusionPipeline synthesizes raw data into complete RoomProject', () {
      const pipeline = SensorFusionPipeline(
        poseInterpolator: PoseInterpolator(maxInterpolationGapMs: 1500),
      );
      final trajectory = [
        const ArPoseKeyframe(
          timestampMs: 1000,
          position: Vec3(1, 0, 1),
          rotation: (0, 0, 0, 1),
        ),
        const ArPoseKeyframe(
          timestampMs: 2000,
          position: Vec3(3, 0, 3),
          rotation: (0, 0, 0, 1),
        ),
      ];

      final rawPackets = [
        const RawWifiPacket(
          timestampMs: 1500,
          bssid: '11:22:33:44:55:66',
          ssid: 'Lab-Mesh',
          rssiDbm: -58,
          frequencyMhz: 5200,
        ),
      ];

      final walls = [
        const WallModel(
          id: 'w1',
          startX: 0,
          startZ: 0,
          endX: 4,
          endZ: 0,
        ),
      ];

      final floor = FloorPolygon(
        vertices: const [
          FloorPoint(x: 0, z: 0),
          FloorPoint(x: 4, z: 0),
          FloorPoint(x: 4, z: 4),
          FloorPoint(x: 0, z: 4),
        ],
      );

      final project = pipeline.fuseProject(
        projectId: 'fused-001',
        roomName: 'Testing Lab',
        trajectory: trajectory,
        rawPackets: rawPackets,
        walls: walls,
        floorBoundary: floor,
        heatmapResolutionMeters: 0.5,
      );

      expect(project.projectId, equals('fused-001'));
      expect(project.wifi.samples.length, equals(1));
      expect(project.wifi.samples.first.posX, closeTo(2.0, 0.05));
      expect(project.wifi.samples.first.posZ, closeTo(2.0, 0.05));
      expect(project.wifi.accessPoints.length, equals(1));
      expect(project.wifi.heatmap, isNotNull);
      expect(project.wifi.heatmap!.cells, isNotEmpty);
      expect(project.quality.geometryConfidence, equals(0.95));
    });
  });
}
