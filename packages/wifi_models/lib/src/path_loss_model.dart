import 'dart:math' as math;

/// Indoor RF Path Loss modeling implementing Log-Distance Path Loss.
class PathLossModel {
  final double referenceDistanceMeters;
  final double pathLossExponent;
  final double shadowFadingStdDevDbm;

  const PathLossModel({
    this.referenceDistanceMeters = 1.0,
    this.pathLossExponent = 2.8,
    this.shadowFadingStdDevDbm = 4.5,
  });

  /// Computes theoretical free space path loss in dB at 1.0 meter.
  static double computeFreeSpacePathLossAt1m(int frequencyMhz) {
    // 20*log10(f_MHz) - 27.55 for d = 1m
    return 20.0 * (math.log(frequencyMhz.toDouble()) / math.ln10) - 27.55;
  }

  /// Estimates received signal strength in dBm at a given [distanceMeters].
  double estimateRssiDbm({
    required double distanceMeters,
    required double txPowerDbm,
    required int frequencyMhz,
  }) {
    final d = math.max(0.1, distanceMeters);
    final pl0 = computeFreeSpacePathLossAt1m(frequencyMhz);
    final logDistance = math.log(d / referenceDistanceMeters) / math.ln10;
    final pathLoss = pl0 + 10.0 * pathLossExponent * logDistance;
    return txPowerDbm - pathLoss;
  }

  /// Estimates distance from RSSI with 1-sigma uncertainty bounds.
  (double estDistance, double minDistance, double maxDistance) estimateDistanceFromRssi({
    required double measuredRssiDbm,
    required double txPowerDbm,
    required int frequencyMhz,
  }) {
    final pl0 = computeFreeSpacePathLossAt1m(frequencyMhz);
    final plMeasured = txPowerDbm - measuredRssiDbm;

    double computeDistance(double pl) {
      final exponent = (pl - pl0) / (10.0 * pathLossExponent);
      return referenceDistanceMeters * math.pow(10.0, exponent).toDouble();
    }

    final est = computeDistance(plMeasured);
    final minD = computeDistance(plMeasured - shadowFadingStdDevDbm);
    final maxD = computeDistance(plMeasured + shadowFadingStdDevDbm);

    return (est, minD, maxD);
  }
}
