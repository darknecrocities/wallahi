import 'dart:math' as math;
import 'package:geometry/geometry.dart';
import 'package:test/test.dart';

void main() {
  group('Geometry Package Tests', () {
    test('Vec2 and Vec3 vector algebra operations', () {
      const v1 = Vec2(3.0, 4.0);
      expect(v1.length, closeTo(5.0, 0.001));

      final v2 = const Vec2(1.0, 2.0) + const Vec2(2.0, 3.0);
      expect(v2.x, equals(3.0));
      expect(v2.z, equals(5.0));

      const v3 = Vec3(1.0, 2.0, 3.0);
      final floor2d = v3.toFloorPlane();
      expect(floor2d.x, equals(1.0));
      expect(floor2d.z, equals(3.0));
    });

    test('PolygonOps containsPoint ray casting accurately detects interior', () {
      final square = [
        const Vec2(0, 0),
        const Vec2(5, 0),
        const Vec2(5, 5),
        const Vec2(0, 5),
      ];

      expect(PolygonOps.containsPoint(const Vec2(2.5, 2.5), square), isTrue);
      expect(PolygonOps.containsPoint(const Vec2(6.0, 2.5), square), isFalse);
      expect(PolygonOps.containsPoint(const Vec2(-1.0, -1.0), square), isFalse);
    });

    test('PolygonOps distanceToSegment calculates perpendicular distance', () {
      final segA = const Vec2(0, 0);
      final segB = const Vec2(4, 0);

      // Perpendicular point directly above segment
      final dist1 = PolygonOps.distanceToSegment(const Vec2(2, 3), segA, segB);
      expect(dist1, closeTo(3.0, 0.001));

      // Point beyond end cap
      final dist2 = PolygonOps.distanceToSegment(const Vec2(7, 0), segA, segB);
      expect(dist2, closeTo(3.0, 0.001));
    });

    test('WallSnappingEngine snaps near-orthogonal wall to exact 90 degrees', () {
      const engine = WallSnappingEngine(angleToleranceDegrees: 15.0);

      // A wall inclined at 85 degrees (near 90 degrees / pi/2)
      final wall = WallSegment2D(
        id: 'w-slanted',
        start: const Vec2(0, 0),
        end: Vec2(4.0 * math.cos(85 * math.pi / 180), 4.0 * math.sin(85 * math.pi / 180)),
      );

      final snapped = engine.snapToOrthogonal(wall);
      expect(snapped.angleRadians, closeTo(math.pi / 2.0, 0.001));
      expect(snapped.end.x, closeTo(0.0, 0.001));
      expect(snapped.end.z, closeTo(4.0, 0.001));
    });

    test('WallSnappingEngine snaps corners within tolerance', () {
      const engine = WallSnappingEngine(cornerDistanceToleranceMeters: 0.3);

      final wall1 = WallSegment2D(
        id: 'w1',
        start: const Vec2(0, 0),
        end: const Vec2(5.0, 0.0),
      );
      // wall2 starts 10 cm away from wall1 end
      final wall2 = WallSegment2D(
        id: 'w2',
        start: const Vec2(5.1, 0.0),
        end: const Vec2(5.1, 4.0),
      );

      final connected = engine.snapCorners([wall1, wall2]);
      expect(connected[0].end.x, closeTo(5.05, 0.001));
      expect(connected[1].start.x, closeTo(5.05, 0.001));
      expect(connected[0].end.x, equals(connected[1].start.x));
    });
  });
}
