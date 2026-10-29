/// Spatial coordinate system specifications and frame definition.
class CoordinateFrame {
  final String upAxis;
  final String floorPlane;
  final String handedness;
  final String units;

  const CoordinateFrame({
    this.upAxis = 'Y',
    this.floorPlane = 'XZ',
    this.handedness = 'right',
    this.units = 'meters',
  });

  Map<String, dynamic> toJson() => {
        'upAxis': upAxis,
        'floorPlane': floorPlane,
        'handedness': handedness,
        'units': units,
      };

  factory CoordinateFrame.fromJson(Map<String, dynamic> json) {
    return CoordinateFrame(
      upAxis: json['upAxis'] as String? ?? 'Y',
      floorPlane: json['floorPlane'] as String? ?? 'XZ',
      handedness: json['handedness'] as String? ?? 'right',
      units: json['units'] as String? ?? 'meters',
    );
  }
}
