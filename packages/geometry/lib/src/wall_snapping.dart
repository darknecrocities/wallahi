import 'dart:math' as math;
import 'vector_math.dart';

/// 2D Wall segment structure for geometric snapping and regularization.
class WallSegment2D {
  final String id;
  final Vec2 start;
  final Vec2 end;
  final double height;
  final double thickness;

  const WallSegment2D({
    required this.id,
    required this.start,
    required this.end,
    this.height = 2.8,
    this.thickness = 0.15,
  });

  double get length => start.distanceTo(end);
  double get angleRadians => math.atan2(end.z - start.z, end.x - start.x);
}

/// Regularization engine aligning raw CV wall estimates into orthogonal architecture.
class WallSnappingEngine {
  final double angleToleranceDegrees;
  final double cornerDistanceToleranceMeters;

  const WallSnappingEngine({
    this.angleToleranceDegrees = 12.0,
    this.cornerDistanceToleranceMeters = 0.25,
  });

  /// Snaps a single wall segment's angle to the nearest orthogonal axis (0, 90, 180, 270).
  WallSegment2D snapToOrthogonal(WallSegment2D wall) {
    final radTolerance = angleToleranceDegrees * (math.pi / 180.0);
    final angle = wall.angleRadians;
    final length = wall.length;

    // Target orthogonal angles: -pi, -pi/2, 0, pi/2, pi
    final targetAngles = [
      -math.pi,
      -math.pi / 2.0,
      0.0,
      math.pi / 2.0,
      math.pi,
    ];

    double closestTarget = angle;
    double minDiff = double.infinity;

    for (final target in targetAngles) {
      final diff = (angle - target).abs();
      if (diff < minDiff && diff <= radTolerance) {
        minDiff = diff;
        closestTarget = target;
      }
    }

    if (minDiff > radTolerance) {
      // Angle exceeds tolerance threshold; keep original direction
      return wall;
    }

    final newEnd = Vec2(
      wall.start.x + length * math.cos(closestTarget),
      wall.start.z + length * math.sin(closestTarget),
    );

    return WallSegment2D(
      id: wall.id,
      start: wall.start,
      end: newEnd,
      height: wall.height,
      thickness: wall.thickness,
    );
  }

  /// Snaps nearby wall endpoints together to close corners and resolve small tracking gaps.
  List<WallSegment2D> snapCorners(List<WallSegment2D> walls) {
    if (walls.length < 2) return walls;
    final result = List<WallSegment2D>.from(walls);

    for (int i = 0; i < result.length; i++) {
      for (int j = 0; j < result.length; j++) {
        if (i == j) continue;
        final w1 = result[i];
        final w2 = result[j];

        // Check if w1.end is close to w2.start
        if (w1.end.distanceTo(w2.start) <= cornerDistanceToleranceMeters) {
          final shared = (w1.end + w2.start) * 0.5;
          result[i] = WallSegment2D(
            id: w1.id,
            start: w1.start,
            end: shared,
            height: w1.height,
            thickness: w1.thickness,
          );
          result[j] = WallSegment2D(
            id: w2.id,
            start: shared,
            end: w2.end,
            height: w2.height,
            thickness: w2.thickness,
          );
        }
      }
    }
    return result;
  }
}
