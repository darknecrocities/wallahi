/// Single discrete cell on the interpolated floor heatmap.
class HeatmapCell {
  final double x;
  final double z;
  final double rssiDbm;
  final double uncertainty; // [0.0, 1.0] where 1.0 is max uncertainty
  final int sampleCount;

  const HeatmapCell({
    required this.x,
    required this.z,
    required this.rssiDbm,
    required this.uncertainty,
    required this.sampleCount,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'z': z,
        'rssiDbm': rssiDbm,
        'uncertainty': uncertainty,
        'sampleCount': sampleCount,
      };

  factory HeatmapCell.fromJson(Map<String, dynamic> json) {
    return HeatmapCell(
      x: (json['x'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
      rssiDbm: (json['rssiDbm'] as num).toDouble(),
      uncertainty: (json['uncertainty'] as num?)?.toDouble() ?? 0.0,
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 1,
    );
  }
}

/// 2D Floor-plane interpolated coverage grid container.
class HeatmapGrid {
  final String method; // 'inverse_distance_weighting' | 'gaussian_rbf'
  final double resolutionMeters;
  final double minX;
  final double maxX;
  final double minZ;
  final double maxZ;
  final List<HeatmapCell> cells;

  const HeatmapGrid({
    this.method = 'inverse_distance_weighting',
    this.resolutionMeters = 0.25,
    required this.minX,
    required this.maxX,
    required this.minZ,
    required this.maxZ,
    required this.cells,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'resolutionMeters': resolutionMeters,
        'bounds': {
          'minX': minX,
          'maxX': maxX,
          'minZ': minZ,
          'maxZ': maxZ,
        },
        'cells': cells.map((c) => c.toJson()).toList(),
      };

  factory HeatmapGrid.fromJson(Map<String, dynamic> json) {
    final bounds = json['bounds'] as Map<String, dynamic>? ?? {};
    final cellList = json['cells'] as List<dynamic>? ?? [];
    return HeatmapGrid(
      method: json['method'] as String? ?? 'inverse_distance_weighting',
      resolutionMeters:
          (json['resolutionMeters'] as num?)?.toDouble() ?? 0.25,
      minX: (bounds['minX'] as num?)?.toDouble() ?? 0.0,
      maxX: (bounds['maxX'] as num?)?.toDouble() ?? 0.0,
      minZ: (bounds['minZ'] as num?)?.toDouble() ?? 0.0,
      maxZ: (bounds['maxZ'] as num?)?.toDouble() ?? 0.0,
      cells: cellList
          .map((c) => HeatmapCell.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
