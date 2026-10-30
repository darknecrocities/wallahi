import 'dart:math' as math;
import 'package:geometry/geometry.dart';

/// RTT range measurement to a known access point or anchor.
class RttAnchorMeasurement {
  final Vec2 anchorPosition;
  final double measuredDistanceMeters;
  final double stdDevMeters;

  const RttAnchorMeasurement({
    required this.anchorPosition,
    required this.measuredDistanceMeters,
    this.stdDevMeters = 1.0,
  });
}

/// Multilateration solver using damped Gauss-Newton non-linear least squares.
class RttMultilaterationSolver {
  final int maxIterations;
  final double convergenceTolerance;

  const RttMultilaterationSolver({
    this.maxIterations = 25,
    this.convergenceTolerance = 1e-4,
  });

  /// Estimates device position in 2D floor coordinates from anchor measurements.
  Vec2? solve(List<RttAnchorMeasurement> measurements) {
    if (measurements.length < 3) return null;

    // Initial centroid guess
    double initX = 0;
    double initZ = 0;
    for (final m in measurements) {
      initX += m.anchorPosition.x;
      initZ += m.anchorPosition.z;
    }
    Vec2 currentEstimate =
        Vec2(initX / measurements.length, initZ / measurements.length);

    for (int iter = 0; iter < maxIterations; iter++) {
      double j11 = 0, j12 = 0, j22 = 0;
      double r1 = 0, r2 = 0;

      for (final m in measurements) {
        final dEst = currentEstimate.distanceTo(m.anchorPosition);
        if (dEst < 1e-6) continue;

        final weight = 1.0 / (m.stdDevMeters * m.stdDevMeters);
        final residual = m.measuredDistanceMeters - dEst;

        // Jacobian components
        final dx = (currentEstimate.x - m.anchorPosition.x) / dEst;
        final dz = (currentEstimate.z - m.anchorPosition.z) / dEst;

        j11 += weight * dx * dx;
        j12 += weight * dx * dz;
        j22 += weight * dz * dz;

        r1 += weight * dx * residual;
        r2 += weight * dz * residual;
      }

      // Add Levenberg damping factor to prevent matrix singularity
      j11 += 1e-3;
      j22 += 1e-3;

      // Invert 2x2 normal equations matrix (J^T * J)
      final det = j11 * j22 - j12 * j12;
      if (det.abs() < 1e-12) break;

      final deltaX = (j22 * r1 - j12 * r2) / det;
      final deltaZ = (-j12 * r1 + j11 * r2) / det;

      currentEstimate = Vec2(
        currentEstimate.x + deltaX,
        currentEstimate.z + deltaZ,
      );

      if (math.sqrt(deltaX * deltaX + deltaZ * deltaZ) <
          convergenceTolerance) {
        break;
      }
    }

    return currentEstimate;
  }
}
