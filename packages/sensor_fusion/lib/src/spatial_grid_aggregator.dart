import 'package:geometry/geometry.dart';
import 'package:wifi_models/wifi_models.dart';

/// Aggregated spatial cell with filtered median RSSI and sample count.
class AggregatedCell {
  final Vec2 center;
  final double medianRssiDbm;
  final int sampleCount;
  final double variance;

  const AggregatedCell({
    required this.center,
    required this.medianRssiDbm,
    required this.sampleCount,
    required this.variance,
  });
}

/// Discretizes floor area into spatial bins and performs median statistical filtering.
class SpatialGridAggregator {
  final double cellSizeMeters;

  const SpatialGridAggregator({this.cellSizeMeters = 0.5});

  (int cellX, int cellZ) _quantize(Vec2 pos) {
    return (
      (pos.x / cellSizeMeters).floor(),
      (pos.z / cellSizeMeters).floor(),
    );
  }

  Vec2 _cellCenter(int cellX, int cellZ) {
    return Vec2(
      (cellX + 0.5) * cellSizeMeters,
      (cellZ + 0.5) * cellSizeMeters,
    );
  }

  /// Groups spatial samples into grid cells and computes robust median statistics.
  List<AggregatedCell> aggregate(List<SpatialRfSample> samples) {
    if (samples.isEmpty) return const [];

    final Map<(int, int), List<double>> cellBins = {};

    for (final s in samples) {
      final key = _quantize(s.position);
      cellBins.putIfAbsent(key, () => []).add(s.rssiDbm);
    }

    final List<AggregatedCell> aggregated = [];

    cellBins.forEach((key, values) {
      values.sort();
      final median = values.length % 2 == 1
          ? values[values.length ~/ 2]
          : (values[(values.length ~/ 2) - 1] + values[values.length ~/ 2]) / 2.0;

      double variance = 0.0;
      if (values.length > 1) {
        final mean = values.reduce((a, b) => a + b) / values.length;
        variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            (values.length - 1);
      }

      aggregated.add(AggregatedCell(
        center: _cellCenter(key.$1, key.$2),
        medianRssiDbm: median,
        sampleCount: values.length,
        variance: variance,
      ));
    });

    return aggregated;
  }
}
