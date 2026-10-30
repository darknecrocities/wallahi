/// Point-in-time Wi-Fi measurement registered to an AR 3D pose.
class WifiSample {
  final String sampleId;
  final String timestampUtc;
  final double posX;
  final double posY;
  final double posZ;
  final String accessPointBssid;
  final int rssiDbm;
  final int frequencyMhz;
  final double? rttDistanceMeters;
  final double? rttStdDevMeters;
  final double positionConfidence;
  final String measurementMethod; // 'rssi' | 'rtt' | 'fused'

  const WifiSample({
    required this.sampleId,
    required this.timestampUtc,
    required this.posX,
    required this.posY,
    required this.posZ,
    required this.accessPointBssid,
    required this.rssiDbm,
    required this.frequencyMhz,
    this.rttDistanceMeters,
    this.rttStdDevMeters,
    this.positionConfidence = 1.0,
    this.measurementMethod = 'rssi',
  });

  Map<String, dynamic> toJson() => {
        'sampleId': sampleId,
        'timestampUtc': timestampUtc,
        'positionMeters': {'x': posX, 'y': posY, 'z': posZ},
        'accessPointBssid': accessPointBssid,
        'rssiDbm': rssiDbm,
        'frequencyMhz': frequencyMhz,
        'rttDistanceMeters': rttDistanceMeters,
        'rttStdDevMeters': rttStdDevMeters,
        'positionConfidence': positionConfidence,
        'measurementMethod': measurementMethod,
      };

  factory WifiSample.fromJson(Map<String, dynamic> json) {
    final pos = json['positionMeters'] as Map<String, dynamic>? ?? {};
    return WifiSample(
      sampleId: json['sampleId'] as String,
      timestampUtc: json['timestampUtc'] as String,
      posX: (pos['x'] as num?)?.toDouble() ?? 0.0,
      posY: (pos['y'] as num?)?.toDouble() ?? 0.0,
      posZ: (pos['z'] as num?)?.toDouble() ?? 0.0,
      accessPointBssid: json['accessPointBssid'] as String,
      rssiDbm: (json['rssiDbm'] as num).toInt(),
      frequencyMhz: (json['frequencyMhz'] as num?)?.toInt() ?? 2412,
      rttDistanceMeters: (json['rttDistanceMeters'] as num?)?.toDouble(),
      rttStdDevMeters: (json['rttStdDevMeters'] as num?)?.toDouble(),
      positionConfidence:
          (json['positionConfidence'] as num?)?.toDouble() ?? 1.0,
      measurementMethod: json['measurementMethod'] as String? ?? 'rssi',
    );
  }
}
