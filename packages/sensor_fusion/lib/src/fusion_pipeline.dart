import 'package:geometry/geometry.dart';
import 'package:room_format/room_format.dart';
import 'package:wifi_models/wifi_models.dart';
import 'pose_interpolator.dart';
import 'spatial_grid_aggregator.dart';
import 'uncertainty_estimator.dart';

/// Raw Wi-Fi packet captured from platform radio scan.
class RawWifiPacket {
  final int timestampMs;
  final String bssid;
  final String ssid;
  final int rssiDbm;
  final int frequencyMhz;
  final double? rttDistanceMeters;
  final double? rttStdDevMeters;

  const RawWifiPacket({
    required this.timestampMs,
    required this.bssid,
    required this.ssid,
    required this.rssiDbm,
    required this.frequencyMhz,
    this.rttDistanceMeters,
    this.rttStdDevMeters,
  });
}

/// Unified sensor fusion coordinator synthesizing AR tracking and radio sensing.
class SensorFusionPipeline {
  final PoseInterpolator poseInterpolator;
  final SpatialGridAggregator gridAggregator;
  final UncertaintyEstimator uncertaintyEstimator;
  final IdwInterpolator idwInterpolator;

  const SensorFusionPipeline({
    this.poseInterpolator = const PoseInterpolator(),
    this.gridAggregator = const SpatialGridAggregator(cellSizeMeters: 0.5),
    this.uncertaintyEstimator = const UncertaintyEstimator(),
    this.idwInterpolator = const IdwInterpolator(power: 2.0),
  });

  /// Fuses raw AR poses, Wi-Fi scans, and room geometry into a unified [RoomProject].
  RoomProject fuseProject({
    required String projectId,
    required String roomName,
    required List<ArPoseKeyframe> trajectory,
    required List<RawWifiPacket> rawPackets,
    required List<WallModel> walls,
    required FloorPolygon floorBoundary,
    double heatmapResolutionMeters = 0.25,
  }) {
    // 1. Spatiotemporal registration: Map Wi-Fi packets to 3D trajectory
    final List<WifiSample> registeredSamples = [];
    final Map<String, AccessPoint> discoveredAps = {};
    int sampleCounter = 1;

    for (final packet in rawPackets) {
      final poseResult = poseInterpolator.interpolatePose(
        packet.timestampMs,
        trajectory,
      );
      if (poseResult == null) continue;

      final (pos, confidence) = poseResult;
      final sampleId = 'sample-${sampleCounter.toString().padLeft(4, '0')}';
      sampleCounter++;

      registeredSamples.add(WifiSample(
        sampleId: sampleId,
        timestampUtc: DateTime.fromMillisecondsSinceEpoch(packet.timestampMs)
            .toUtc()
            .toIso8601String(),
        posX: pos.x,
        posY: pos.y,
        posZ: pos.z,
        accessPointBssid: packet.bssid,
        rssiDbm: packet.rssiDbm,
        frequencyMhz: packet.frequencyMhz,
        rttDistanceMeters: packet.rttDistanceMeters,
        rttStdDevMeters: packet.rttStdDevMeters,
        positionConfidence: confidence,
        measurementMethod:
            packet.rttDistanceMeters != null ? 'rtt' : 'rssi',
      ));

      discoveredAps.putIfAbsent(
        packet.bssid,
        () => AccessPoint(
          bssid: packet.bssid,
          ssid: packet.ssid,
          frequencyMhz: packet.frequencyMhz,
          channel: _frequencyToChannel(packet.frequencyMhz),
        ),
      );
    }

    // 2. Spatial aggregation and IDW Heatmap calculation
    final floorVertices =
        floorBoundary.vertices.map((v) => Vec2(v.x, v.z)).toList();
    final bounds = PolygonOps.computeBounds(floorVertices, padding: 0.25);

    final rfSamples = registeredSamples
        .map((s) => SpatialRfSample(
              position: Vec2(s.posX, s.posZ),
              rssiDbm: s.rssiDbm.toDouble(),
              confidence: s.positionConfidence,
            ))
        .toList();

    final List<HeatmapCell> heatmapCells = [];
    for (double x = bounds.minX;
        x <= bounds.maxX;
        x += heatmapResolutionMeters) {
      for (double z = bounds.minZ;
          z <= bounds.maxZ;
          z += heatmapResolutionMeters) {
        final probe = Vec2(x, z);
        if (floorVertices.isNotEmpty &&
            !PolygonOps.containsPoint(probe, floorVertices)) {
          continue;
        }

        final result = idwInterpolator.interpolate(probe, rfSamples);
        heatmapCells.add(HeatmapCell(
          x: x,
          z: z,
          rssiDbm: result.estimatedRssiDbm,
          uncertainty: result.uncertainty,
          sampleCount: result.contributingSamples,
        ));
      }
    }

    // 3. Quality evaluation
    final samplePoints = rfSamples.map((s) => s.position).toList();
    final rescanRecs = uncertaintyEstimator.detectRescanAreas(
      floorPolygon: floorVertices,
      sampleLocations: samplePoints,
    );
    final coverageConfidence = uncertaintyEstimator.computeCoverageConfidence(
      sampleLocations: samplePoints,
      floorAreaSqMeters: floorBoundary.areaSquareMeters,
    );

    return RoomProject(
      projectId: projectId,
      name: roomName,
      createdAtUtc: DateTime.now().toUtc().toIso8601String(),
      room: RoomGeometry(
        walls: walls,
        floorBoundary: floorBoundary,
      ),
      wifi: WifiDataset(
        accessPoints: discoveredAps.values.toList(),
        samples: registeredSamples,
        heatmap: HeatmapGrid(
          resolutionMeters: heatmapResolutionMeters,
          minX: bounds.minX,
          maxX: bounds.maxX,
          minZ: bounds.minZ,
          maxZ: bounds.maxZ,
          cells: heatmapCells,
        ),
      ),
      quality: QualityMetrics(
        geometryConfidence: 0.95,
        wifiCoverageConfidence: coverageConfidence,
        meanSampleDensityPerSqMeter: floorBoundary.areaSquareMeters > 0
            ? registeredSamples.length / floorBoundary.areaSquareMeters
            : 0.0,
        rescanPromptCount: rescanRecs.length,
      ),
    );
  }

  static int _frequencyToChannel(int freq) {
    if (freq >= 2412 && freq <= 2484) return ((freq - 2412) ~/ 5) + 1;
    if (freq >= 5170 && freq <= 5825) return ((freq - 5000) ~/ 5);
    return 1;
  }
}
