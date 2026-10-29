import 'dart:math' as math;
import 'package:geometry/geometry.dart';

/// Single spatial radio observation point.
class SpatialRfSample {
  final Vec2 position;
  final double rssiDbm;
  final double confidence;

  const SpatialRfSample({
    required this.position,
    required this.rssiDbm,
    this.confidence = 1.0,
  });
}

/// Interpolated point evaluation result.
class RfInterpolationResult {
  final double estimatedRssiDbm;
  final double uncertainty; // [0.0, 1.0]
  final int contributingSamples;

  const RfInterpolationResult({
    required this.estimatedRssiDbm,
    required this.uncertainty,
    required this.contributingSamples,
  });
}

/// 2D Floor plane Inverse Distance Weighting (IDW) interpolator.
class IdwInterpolator {
  final double power;
  final double smoothingEpsilon;
  final double maxSearchRadiusMeters;
  final double defaultRssiFloor;

  const IdwInterpolator({
    this.power = 2.0,
    this.smoothingEpsilon = 0.15,
    this.maxSearchRadiusMeters = 5.0,
    this.defaultRssiFloor = -95.0,
  });

  /// Interpolates RSSI and uncertainty at target floor position [point].
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
    int contributingCount = 0;

    for (final sample in samples) {
      final distance = point.distanceTo(sample.position);
      if (distance < minDistance) {
        minDistance = distance;
      }

      if (distance > maxSearchRadiusMeters) continue;

      final weight = (sample.confidence) /
          math.pow(distance + smoothingEpsilon, power);
      totalWeight += weight;
      weightedRssiSum += weight * sample.rssiDbm;
      contributingCount++;
    }

    if (totalWeight <= 1e-9 || contributingCount == 0) {
      return RfInterpolationResult(
        estimatedRssiDbm: defaultRssiFloor,
        uncertainty: 1.0,
        contributingSamples: 0,
      );
    }

    final estimatedRssi = weightedRssiSum / totalWeight;
    // Uncertainty rises exponentially with distance from nearest measurement
    final uncertainty = 1.0 - math.exp(-minDistance / 1.5);

    return RfInterpolationResult(
      estimatedRssiDbm: estimatedRssi,
      uncertainty: math.min(1.0, math.max(0.0, uncertainty)),
      contributingSamples: contributingCount,
    );
  }
}
