import 'dart:convert';
import 'package:room_format/room_format.dart';
import 'package:test/test.dart';

void main() {
  group('RoomProject Schema & Serialization Tests', () {
    test('FloorPolygon calculates area and centroid correctly', () {
      final polygon = FloorPolygon(
        vertices: const [
          FloorPoint(x: 0, z: 0),
          FloorPoint(x: 4, z: 0),
          FloorPoint(x: 4, z: 5),
          FloorPoint(x: 0, z: 5),
        ],
      );

      expect(polygon.areaSquareMeters, closeTo(20.0, 0.001));
      expect(polygon.centroid.x, closeTo(2.0, 0.001));
      expect(polygon.centroid.z, closeTo(2.5, 0.001));
    });

    test('WallModel calculates length and angle accurately', () {
      const wall = WallModel(
        id: 'wall-01',
        startX: 0.0,
        startZ: 0.0,
        endX: 3.0,
        endZ: 4.0,
        heightMeters: 2.8,
      );

      expect(wall.lengthMeters, closeTo(5.0, 0.001));
      expect(wall.angleRadians, closeTo(0.927, 0.01));
    });

    test('Round-trip JSON serialization preserves all invariants', () {
      final project = RoomProject(
        projectId: 'project-test-101',
        name: 'Conference Room Alpha',
        createdAtUtc: '2026-10-30T08:00:00Z',
        room: RoomGeometry(
          walls: const [
            WallModel(
              id: 'w1',
              startX: 0,
              startZ: 0,
              endX: 5,
              endZ: 0,
              heightMeters: 3.0,
            ),
          ],
          openings: const [
            OpeningModel(
              id: 'd1',
              wallId: 'w1',
              type: 'door',
              offsetMeters: 1.2,
              widthMeters: 0.9,
            ),
          ],
          floorBoundary: const FloorPolygon(
            vertices: [
              FloorPoint(x: 0, z: 0),
              FloorPoint(x: 5, z: 0),
              FloorPoint(x: 5, z: 4),
              FloorPoint(x: 0, z: 4),
            ],
          ),
        ),
        wifi: WifiDataset(
          accessPoints: const [
            AccessPoint(
              bssid: 'aa:bb:cc:dd:ee:01',
              ssid: 'Enterprise-5G',
              frequencyMhz: 5180,
              channel: 36,
            ),
          ],
          samples: const [
            WifiSample(
              sampleId: 's1',
              timestampUtc: '2026-10-30T08:01:00Z',
              posX: 2.5,
              posY: 1.2,
              posZ: 2.0,
              accessPointBssid: 'aa:bb:cc:dd:ee:01',
              rssiDbm: -55,
              frequencyMhz: 5180,
            ),
          ],
          heatmap: const HeatmapGrid(
            minX: 0,
            maxX: 5,
            minZ: 0,
            maxZ: 4,
            cells: [
              HeatmapCell(
                x: 1.0,
                z: 1.0,
                rssiDbm: -58.0,
                uncertainty: 0.15,
                sampleCount: 3,
              ),
            ],
          ),
        ),
        quality: const QualityMetrics(
          geometryConfidence: 0.95,
          wifiCoverageConfidence: 0.90,
          meanSampleDensityPerSqMeter: 1.5,
        ),
      );

      final jsonMap = project.toJson();
      final jsonString = jsonEncode(jsonMap);
      final decodedProject =
          RoomProject.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

      expect(decodedProject.projectId, equals('project-test-101'));
      expect(decodedProject.room.walls.length, equals(1));
      expect(decodedProject.room.walls.first.lengthMeters, closeTo(5.0, 0.001));
      expect(decodedProject.wifi.samples.first.rssiDbm, equals(-55));
      expect(decodedProject.wifi.heatmap?.cells.first.rssiDbm, equals(-58.0));
      expect(decodedProject.quality.geometryConfidence, equals(0.95));
    });
  });
}
