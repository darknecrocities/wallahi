/// Architectural opening (door, window, portal) attached to a parent wall.
class OpeningModel {
  final String id;
  final String wallId;
  final String type; // 'door', 'window', 'portal'
  final double offsetMeters;
  final double widthMeters;
  final double heightMeters;

  const OpeningModel({
    required this.id,
    required this.wallId,
    required this.type,
    required this.offsetMeters,
    required this.widthMeters,
    this.heightMeters = 2.1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'wallId': wallId,
        'type': type,
        'offsetMeters': offsetMeters,
        'widthMeters': widthMeters,
        'heightMeters': heightMeters,
      };

  factory OpeningModel.fromJson(Map<String, dynamic> json) {
    return OpeningModel(
      id: json['id'] as String,
      wallId: json['wallId'] as String,
      type: json['type'] as String? ?? 'door',
      offsetMeters: (json['offsetMeters'] as num).toDouble(),
      widthMeters: (json['widthMeters'] as num).toDouble(),
      heightMeters: (json['heightMeters'] as num?)?.toDouble() ?? 2.1,
    );
  }
}
