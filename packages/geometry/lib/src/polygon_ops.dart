import 'dart:math' as math;
import 'vector_math.dart';

/// Computational polygon operations for room floor boundaries.
class PolygonOps {
  /// Ray-casting test determining whether [point] lies within [polygonVertices].
  static bool containsPoint(Vec2 point, List<Vec2> polygonVertices) {
    if (polygonVertices.length < 3) return false;
    bool inside = false;
    final n = polygonVertices.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final pi = polygonVertices[i];
      final pj = polygonVertices[j];

      final intersects = ((pi.z > point.z) != (pj.z > point.z)) &&
          (point.x < (pj.x - pi.x) * (point.z - pi.z) / (pj.z - pi.z) + pi.x);
      if (intersects) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Calculates perpendicular distance from [point] to line segment ([segA], [segB]).
  static double distanceToSegment(Vec2 point, Vec2 segA, Vec2 segB) {
    final ab = segB - segA;
    final lengthSq = ab.lengthSquared;
    if (lengthSq < 1e-9) return point.distanceTo(segA);

    final t = math.max(0.0, math.min(1.0, (point - segA).dot(ab) / lengthSq));
    final projection = segA + ab * t;
    return point.distanceTo(projection);
  }

  /// Calculates Axis-Aligned Bounding Box enclosing a set of 2D points.
  static BoundingBox2D computeBounds(List<Vec2> points, {double padding = 0.5}) {
    if (points.isEmpty) {
      return const BoundingBox2D(minX: 0, maxX: 0, minZ: 0, maxZ: 0);
    }
    double minX = points.first.x;
    double maxX = points.first.x;
    double minZ = points.first.z;
    double maxZ = points.first.z;

    for (final p in points) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minZ = math.min(minZ, p.z);
      maxZ = math.max(maxZ, p.z);
    }

    return BoundingBox2D(
      minX: minX - padding,
      maxX: maxX + padding,
      minZ: minZ - padding,
      maxZ: maxZ + padding,
    );
  }
}
