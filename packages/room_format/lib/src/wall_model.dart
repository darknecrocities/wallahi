import 'dart:math' as math;

/// 3D Wall segment representation projected from computer vision plane fits.
class WallModel {
  final String id;
  final double startX;
  final double startZ;
  final double endX;
  final double endZ;
  final double heightMeters;
  final double thicknessMeters;
  final double confidence;
  final String material;

  const WallModel({
    required this.id,
    required this.startX,
    required this.startZ,
    required this.endX,
    required this.endZ,
    this.heightMeters = 2.8,
    this.thicknessMeters = 0.15,
    this.confidence = 1.0,
    this.material = 'drywall',
  });

  double get lengthMeters {
    final dx = endX - startX;
    final dz = endZ - startZ;
    return math.sqrt(dx * dx + dz * dz);
  }

  double get angleRadians {
    return math.atan2(endZ - startZ, endX - startX);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startX': startX,
        'startZ': startZ,
        'endX': endX,
        'endZ': endZ,
        'heightMeters': heightMeters,
        'thicknessMeters': thicknessMeters,
        'confidence': confidence,
        'material': material,
      };

  factory WallModel.fromJson(Map<String, dynamic> json) {
    return WallModel(
      id: json['id'] as String,
      startX: (json['startX'] as num).toDouble(),
      startZ: (json['startZ'] as num).toDouble(),
      endX: (json['endX'] as num).toDouble(),
      endZ: (json['endZ'] as num).toDouble(),
      heightMeters: (json['heightMeters'] as num?)?.toDouble() ?? 2.8,
      thicknessMeters: (json['thicknessMeters'] as num?)?.toDouble() ?? 0.15,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      material: json['material'] as String? ?? 'drywall',
    );
  }
}
