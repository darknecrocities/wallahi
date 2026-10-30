import 'dart:math' as math;
import 'package:geometry/geometry.dart';

/// 6-DoF AR tracking pose at an exact point in time.
class ArPoseKeyframe {
  final int timestampMs;
  final Vec3 position;
  final (double qx, double qy, double qz, double qw) rotation;
  final double trackingConfidence; // 0.0 to 1.0

  const ArPoseKeyframe({
    required this.timestampMs,
    required this.position,
    required this.rotation,
    this.trackingConfidence = 1.0,
  });
}

/// Spatiotemporal pose associator with tracking quality gating.
class PoseInterpolator {
  final int maxInterpolationGapMs;
  final double maxVelocityMps;

  const PoseInterpolator({
    this.maxInterpolationGapMs = 500,
    this.maxVelocityMps = 2.5,
  });

  /// Finds and interpolates the 3D position corresponding to [targetTimestampMs].
  (Vec3 position, double confidence)? interpolatePose(
    int targetTimestampMs,
    List<ArPoseKeyframe> trajectory,
  ) {
    if (trajectory.isEmpty) return null;
    if (trajectory.length == 1) {
      final diff = (targetTimestampMs - trajectory.first.timestampMs).abs();
      if (diff > maxInterpolationGapMs) return null;
      return (trajectory.first.position, trajectory.first.trackingConfidence);
    }

    // Binary search or linear scan for enclosing keyframes
    int idxA = -1;
    int idxB = -1;

    for (int i = 0; i < trajectory.length - 1; i++) {
      if (trajectory[i].timestampMs <= targetTimestampMs &&
          trajectory[i + 1].timestampMs >= targetTimestampMs) {
        idxA = i;
        idxB = i + 1;
        break;
      }
    }

    if (idxA == -1) {
      // Out of bounds; check if near ends
      if (targetTimestampMs < trajectory.first.timestampMs) {
        final diff = trajectory.first.timestampMs - targetTimestampMs;
        if (diff <= maxInterpolationGapMs) {
          return (trajectory.first.position, trajectory.first.trackingConfidence * 0.8);
        }
      } else {
        final diff = targetTimestampMs - trajectory.last.timestampMs;
        if (diff <= maxInterpolationGapMs) {
          return (trajectory.last.position, trajectory.last.trackingConfidence * 0.8);
        }
      }
      return null;
    }

    final kA = trajectory[idxA];
    final kB = trajectory[idxB];
    final dt = kB.timestampMs - kA.timestampMs;
    if (dt > maxInterpolationGapMs) return null;

    final alpha = dt == 0 ? 0.0 : (targetTimestampMs - kA.timestampMs) / dt;
    final interpolatedPos = kA.position * (1.0 - alpha) + kB.position * alpha;

    // Velocity gating
    final dist = kA.position.distanceTo(kB.position);
    final velocity = dt > 0 ? (dist / (dt / 1000.0)) : 0.0;
    double confidence =
        math.min(kA.trackingConfidence, kB.trackingConfidence);
    if (velocity > maxVelocityMps) {
      confidence *= 0.5; // Motion blur penalty
    }

    return (interpolatedPos, confidence);
  }
}
