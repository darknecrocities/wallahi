/// Floor boundary polygon vertex in the metric XZ plane.
class FloorPoint {
  final double x;
  final double z;

  const FloorPoint({required this.x, required this.z});

  Map<String, dynamic> toJson() => {'x': x, 'z': z};

  factory FloorPoint.fromJson(Map<String, dynamic> json) {
    return FloorPoint(
      x: (json['x'] as num).toDouble(),
      z: (json['z'] as num).toDouble(),
    );
  }
}

/// Bounding floor perimeter extracted from AR ground plane tracking.
class FloorPolygon {
  final List<FloorPoint> vertices;

  const FloorPolygon({required this.vertices});

  /// Computes floor polygon area using the shoelace formula.
  double get areaSquareMeters {
    if (vertices.length < 3) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % vertices.length];
      sum += (p1.x * p2.z) - (p2.x * p1.z);
    }
    return (sum.abs()) / 2.0;
  }

  /// Calculates geometric centroid of the floor boundary.
  FloorPoint get centroid {
    if (vertices.isEmpty) return const FloorPoint(x: 0, z: 0);
    double cx = 0;
    double cz = 0;
    for (final v in vertices) {
      cx += v.x;
      cz += v.z;
    }
    return FloorPoint(x: cx / vertices.length, z: cz / vertices.length);
  }

  Map<String, dynamic> toJson() => {
        'vertices': vertices.map((v) => v.toJson()).toList(),
      };

  factory FloorPolygon.fromJson(Map<String, dynamic> json) {
    final list = json['vertices'] as List<dynamic>? ?? [];
    return FloorPolygon(
      vertices: list
          .map((item) => FloorPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
