import 'package:geometry/geometry.dart';
import 'package:test/test.dart';
import 'package:wifi_models/wifi_models.dart';

void main() {
  group('Wi-Fi Models & Interpolation Tests', () {
    test('PathLossModel computes realistic indoor signal decay', () {
      const model = PathLossModel(pathLossExponent: 3.0);
      final fspl1m = PathLossModel.computeFreeSpacePathLossAt1m(5180);
      expect(fspl1m, closeTo(46.7, 0.5));

      final rssi1m = model.estimateRssiDbm(
        distanceMeters: 1.0,
        txPowerDbm: 20.0,
        frequencyMhz: 5180,
      );
      final rssi5m = model.estimateRssiDbm(
        distanceMeters: 5.0,
        txPowerDbm: 20.0,
        frequencyMhz: 5180,
      );

      // RSSI at 5m must be significantly lower than at 1m
      expect(rssi1m, greaterThan(rssi5m));
      expect(rssi1m - rssi5m, closeTo(20.9, 1.0));
    });

    test('IdwInterpolator interpolates values with low uncertainty near samples', () {
      const interpolator = IdwInterpolator(power: 2.0);
      final samples = [
        const SpatialRfSample(position: Vec2(0, 0), rssiDbm: -40.0),
        const SpatialRfSample(position: Vec2(4, 0), rssiDbm: -80.0),
      ];

      // Exact midpoint
      final midpoint = interpolator.interpolate(const Vec2(2, 0), samples);
      expect(midpoint.estimatedRssiDbm, closeTo(-60.0, 0.5));
      expect(midpoint.contributingSamples, equals(2));

      // Close to strong sample
      final nearSample1 = interpolator.interpolate(const Vec2(0.1, 0), samples);
      expect(nearSample1.estimatedRssiDbm, closeTo(-40.0, 3.0));
      expect(nearSample1.uncertainty, lessThan(0.2));
    });

    test('RbfInterpolator computes Gaussian smooth field', () {
      const rbf = RbfInterpolator(gamma: 0.5);
      final samples = [
        const SpatialRfSample(position: Vec2(0, 0), rssiDbm: -50.0),
      ];

      final resultAtOrigin = rbf.interpolate(const Vec2(0, 0), samples);
      expect(resultAtOrigin.estimatedRssiDbm, closeTo(-50.0, 0.1));
      expect(resultAtOrigin.uncertainty, closeTo(0.0, 0.01));
    });

    test('RttMultilaterationSolver recovers target coordinates from ranges', () {
      const solver = RttMultilaterationSolver();

      // True target at (2.0, 3.0)
      const target = Vec2(2.0, 3.0);
      final anchors = [
        const Vec2(0.0, 0.0),
        const Vec2(5.0, 0.0),
        const Vec2(2.0, 6.0),
      ];

      final measurements = anchors.map((a) {
        return RttAnchorMeasurement(
          anchorPosition: a,
          measuredDistanceMeters: target.distanceTo(a),
        );
      }).toList();

      final solved = solver.solve(measurements);
      expect(solved, isNotNull);
      expect(solved!.x, closeTo(2.0, 0.05));
      expect(solved.z, closeTo(3.0, 0.05));
    });
  });
}
