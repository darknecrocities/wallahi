import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_format/room_format.dart';
import 'package:wallahi/features/export/export_service.dart';
import 'package:wallahi/main.dart';

void main() {
  testWidgets('Wallahi App loads HomeScreen with initiate scan action',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WallahiApp()));
    await tester.pumpAndSettle();

    expect(find.text('Wallahi Spatial RF'), findsOneWidget);
    expect(find.text('Indoor Spatial Computing'), findsOneWidget);
    expect(find.text('Initiate New Spatial Scan'), findsOneWidget);
  });

  test('ExportService formats valid JSON, GeoJSON, and OBJ outputs', () {
    const project = RoomProject(
      projectId: 'exp-01',
      name: 'Lab 1',
      createdAtUtc: '2026-10-30T08:00:00Z',
      room: RoomGeometry(
        walls: [
          WallModel(
            id: 'w1',
            startX: 0,
            startZ: 0,
            endX: 4,
            endZ: 0,
            heightMeters: 3.0,
          ),
        ],
        floorBoundary: FloorPolygon(
          vertices: [
            FloorPoint(x: 0, z: 0),
            FloorPoint(x: 4, z: 0),
            FloorPoint(x: 4, z: 4),
            FloorPoint(x: 0, z: 4),
          ],
        ),
      ),
      wifi: WifiDataset(
        accessPoints: [
          AccessPoint(
            bssid: 'aa:bb:cc:dd:ee:ff',
            ssid: 'Campus-Net',
            frequencyMhz: 5240,
            channel: 48,
            estimatedPosX: 2.0,
            estimatedPosZ: 2.0,
          ),
        ],
        samples: [],
      ),
    );

    final jsonOut = ExportService.exportToJson(project);
    expect(jsonOut, contains('exp-01'));
    expect(jsonOut, contains('Campus-Net'));

    final geoJsonOut = ExportService.exportToGeoJson(project);
    expect(geoJsonOut, contains('FeatureCollection'));
    expect(geoJsonOut, contains('Polygon'));

    final objOut = ExportService.exportToObj(project);
    expect(objOut, contains('v 0.0 0.0 0.0'));
    expect(objOut, contains('f 1 2 3'));
  });
}
