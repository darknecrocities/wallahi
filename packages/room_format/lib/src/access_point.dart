/// Wi-Fi Access Point node with optional estimated spatial coordinates.
class AccessPoint {
  final String bssid;
  final String ssid;
  final int frequencyMhz;
  final int channel;
  final int? txPowerDbm;
  final double? estimatedPosX;
  final double? estimatedPosY;
  final double? estimatedPosZ;
  final double positionConfidence;

  const AccessPoint({
    required this.bssid,
    required this.ssid,
    required this.frequencyMhz,
    required this.channel,
    this.txPowerDbm,
    this.estimatedPosX,
    this.estimatedPosY,
    this.estimatedPosZ,
    this.positionConfidence = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'bssid': bssid,
        'ssid': ssid,
        'frequencyMhz': frequencyMhz,
        'channel': channel,
        'txPowerDbm': txPowerDbm,
        'estimatedPosition': estimatedPosX != null
            ? {'x': estimatedPosX, 'y': estimatedPosY, 'z': estimatedPosZ}
            : null,
        'positionConfidence': positionConfidence,
      };

  factory AccessPoint.fromJson(Map<String, dynamic> json) {
    final pos = json['estimatedPosition'] as Map<String, dynamic>?;
    return AccessPoint(
      bssid: json['bssid'] as String,
      ssid: json['ssid'] as String? ?? 'Hidden Network',
      frequencyMhz: (json['frequencyMhz'] as num?)?.toInt() ?? 2412,
      channel: (json['channel'] as num?)?.toInt() ?? 1,
      txPowerDbm: (json['txPowerDbm'] as num?)?.toInt(),
      estimatedPosX: (pos?['x'] as num?)?.toDouble(),
      estimatedPosY: (pos?['y'] as num?)?.toDouble(),
      estimatedPosZ: (pos?['z'] as num?)?.toDouble(),
      positionConfidence:
          (json['positionConfidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
