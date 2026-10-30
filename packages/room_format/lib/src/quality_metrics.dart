/// Calibrated quality and coverage statistics for a completed scan.
class QualityMetrics {
  final double geometryConfidence;
  final double wifiCoverageConfidence;
  final double meanSampleDensityPerSqMeter;
  final int rescanPromptCount;

  const QualityMetrics({
    this.geometryConfidence = 1.0,
    this.wifiCoverageConfidence = 1.0,
    this.meanSampleDensityPerSqMeter = 0.0,
    this.rescanPromptCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'geometryConfidence': geometryConfidence,
        'wifiCoverageConfidence': wifiCoverageConfidence,
        'meanSampleDensityPerSqMeter': meanSampleDensityPerSqMeter,
        'rescanPromptCount': rescanPromptCount,
      };

  factory QualityMetrics.fromJson(Map<String, dynamic> json) {
    return QualityMetrics(
      geometryConfidence:
          (json['geometryConfidence'] as num?)?.toDouble() ?? 1.0,
      wifiCoverageConfidence:
          (json['wifiCoverageConfidence'] as num?)?.toDouble() ?? 1.0,
      meanSampleDensityPerSqMeter:
          (json['meanSampleDensityPerSqMeter'] as num?)?.toDouble() ?? 0.0,
      rescanPromptCount: (json['rescanPromptCount'] as num?)?.toInt() ?? 0,
    );
  }
}
