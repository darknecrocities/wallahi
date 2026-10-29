import 'dart:math' as math;
import 'package:geometry/geometry.dart';
import 'idw_interpolator.dart';

/// Gaussian Radial Basis Function (RBF) kernel interpolator for spatial RF field.
class RbfInterpolator {
  final double gamma; // Kernel bandwidth scaling parameter
  final double defaultRssiFloor;

  const RbfInterpolator({
    this.gamma = 0.5,
    this.defaultRssiFloor = -95.0,
  });

  /// Evaluates Gaussian RBF at [point] given [samples].
  RfInterpolationResult interpolate(
    Vec2 point,
    List<SpatialRfSample> samples,
  ) {
    if (samples.isEmpty) {
      return RfInterpolationResult(
        estimatedRssiDbm: defaultRssiFloor,
        uncertainty: 1.0,
        contributingSamples: 0,
      );
    }

    double totalWeight = 0.0;
    double weightedRssiSum = 0.0;
    double minDistance = double.infinity;

    for (final sample in samples) {
      final distance = point.distanceTo(sample.position);
      if (distance < minDistance) {
        minDistance = distance;
      }

      // Gaussian kernel: K(d) = exp(-gamma * d^2)
      final kernel = math.exp(-gamma * distance * distance);
      final weight = kernel * sample.confidence;

      totalWeight += weight;
      weightedRssiSum += weight * sample.rssiDbm;
    }

    if (totalWeight <= 1e-9) {
      return RfInterpolationResult(
        estimatedRssiDbm: defaultRssiFloor,
        uncertainty: 1.0,
        contributingSamples: 0,
      );
    }

    final estimatedRssi = weightedRssiSum / totalWeight;
    final uncertainty = 1.0 - math.exp(-gamma * minDistance * minDistance);

    return RfInterpolationResult(
      estimatedRssiDbm: estimatedRssi,
      uncertainty: math.min(1.0, math.max(0.0, uncertainty)),
      contributingSamples: samples.length,
    );
  }
}
