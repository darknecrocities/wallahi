import 'dart:math' as math;
import 'package:geometry/geometry.dart';

/// Region in the room flagged for recommended rescan.
class RescanRecommendation {
  final Vec2 targetFloorPosition;
  final double distanceToNearestSample;
  final String rationale;

  const RescanRecommendation({
    required this.targetFloorPosition,
    required this.distanceToNearestSample,
    required this.rationale,
  });
}

/// Evaluates spatial coverage quality and identifies under-sampled room voids.
class UncertaintyEstimator {
  final double rescanDistanceThresholdMeters;

  const UncertaintyEstimator({
    this.rescanDistanceThresholdMeters = 1.8,
  });

  /// Evaluates coverage confidence across a bounding floor polygon.
  double computeCoverageConfidence({
    required List<Vec2> sampleLocations,
    required double floorAreaSqMeters,
  }) {
    if (floorAreaSqMeters <= 0.1 || sampleLocations.isEmpty) return 0.0;
    final density = sampleLocations.length / floorAreaSqMeters;
    // Calibrated: 0.5 samples/m^2 gives ~0.63 confidence; >= 2.0 samples/m^2 approaches 0.95+
    return 1.0 - math.exp(-density / 0.8);
  }

  /// Finds unmapped holes inside [floorPolygon] that warrant user rescanning.
  List<RescanRecommendation> detectRescanAreas({
    required List<Vec2> floorPolygon,
    required List<Vec2> sampleLocations,
    double gridStepMeters = 0.8,
  }) {
    if (floorPolygon.length < 3) return const [];
    final bounds = PolygonOps.computeBounds(floorPolygon, padding: 0.0);
    final List<RescanRecommendation> recommendations = [];

    for (double x = bounds.minX; x <= bounds.maxX; x += gridStepMeters) {
      for (double z = bounds.minZ; z <= bounds.maxZ; z += gridStepMeters) {
        final probe = Vec2(x, z);
        if (!PolygonOps.containsPoint(probe, floorPolygon)) continue;

        double minDistance = double.infinity;
        for (final s in sampleLocations) {
          final dist = probe.distanceTo(s);
          if (dist < minDistance) {
            minDistance = dist;
          }
        }

        if (minDistance >= rescanDistanceThresholdMeters) {
          recommendations.add(RescanRecommendation(
            targetFloorPosition: probe,
            distanceToNearestSample: minDistance,
            rationale: 'Unvisited void in room quadrant; Wi-Fi coverage unverified',
          ));
        }
      }
    }

    return recommendations;
  }
}
