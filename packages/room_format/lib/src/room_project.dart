import 'coordinate_frame.dart';
import 'wall_model.dart';
import 'opening_model.dart';
import 'floor_polygon.dart';
import 'wifi_sample.dart';
import 'access_point.dart';
import 'heatmap_data.dart';
import 'quality_metrics.dart';

/// Room geometry container.
class RoomGeometry {
  final List<WallModel> walls;
  final List<OpeningModel> openings;
  final FloorPolygon floorBoundary;

  const RoomGeometry({
    required this.walls,
    this.openings = const [],
    required this.floorBoundary,
  });

  Map<String, dynamic> toJson() => {
        'walls': walls.map((w) => w.toJson()).toList(),
        'openings': openings.map((o) => o.toJson()).toList(),
        'floorBoundary': floorBoundary.toJson(),
      };

  factory RoomGeometry.fromJson(Map<String, dynamic> json) {
    final wallsList = json['walls'] as List<dynamic>? ?? [];
    final openingsList = json['openings'] as List<dynamic>? ?? [];
    final floor = json['floorBoundary'] as Map<String, dynamic>? ?? {};
    return RoomGeometry(
      walls: wallsList
          .map((w) => WallModel.fromJson(w as Map<String, dynamic>))
          .toList(),
      openings: openingsList
          .map((o) => OpeningModel.fromJson(o as Map<String, dynamic>))
          .toList(),
      floorBoundary: FloorPolygon.fromJson(floor),
    );
  }
}

/// Radio dataset container.
class WifiDataset {
  final List<AccessPoint> accessPoints;
  final List<WifiSample> samples;
  final HeatmapGrid? heatmap;

  const WifiDataset({
    required this.accessPoints,
    required this.samples,
    this.heatmap,
  });

  Map<String, dynamic> toJson() => {
        'accessPoints': accessPoints.map((a) => a.toJson()).toList(),
        'samples': samples.map((s) => s.toJson()).toList(),
        'heatmap': heatmap?.toJson(),
      };

  factory WifiDataset.fromJson(Map<String, dynamic> json) {
    final apList = json['accessPoints'] as List<dynamic>? ?? [];
    final sampleList = json['samples'] as List<dynamic>? ?? [];
    final hm = json['heatmap'] as Map<String, dynamic>?;
    return WifiDataset(
      accessPoints: apList
          .map((a) => AccessPoint.fromJson(a as Map<String, dynamic>))
          .toList(),
      samples: sampleList
          .map((s) => WifiSample.fromJson(s as Map<String, dynamic>))
          .toList(),
      heatmap: hm != null ? HeatmapGrid.fromJson(hm) : null,
    );
  }
}

/// Canonical root project container for Wallahi indoor mapping.
class RoomProject {
  final String schemaVersion;
  final String projectId;
  final String name;
  final String createdAtUtc;
  final CoordinateFrame coordinateSystem;
  final RoomGeometry room;
  final WifiDataset wifi;
  final QualityMetrics quality;

  const RoomProject({
    this.schemaVersion = '1.0',
    required this.projectId,
    required this.name,
    required this.createdAtUtc,
    this.coordinateSystem = const CoordinateFrame(),
    required this.room,
    required this.wifi,
    this.quality = const QualityMetrics(),
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'projectId': projectId,
        'name': name,
        'createdAtUtc': createdAtUtc,
        'units': coordinateSystem.units,
        'coordinateSystem': coordinateSystem.toJson(),
        'room': room.toJson(),
        'wifi': wifi.toJson(),
        'quality': quality.toJson(),
      };

  factory RoomProject.fromJson(Map<String, dynamic> json) {
    return RoomProject(
      schemaVersion: json['schemaVersion'] as String? ?? '1.0',
      projectId: json['projectId'] as String,
      name: json['name'] as String? ?? 'Untitled Room',
      createdAtUtc: json['createdAtUtc'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
      coordinateSystem: json['coordinateSystem'] != null
          ? CoordinateFrame.fromJson(
              json['coordinateSystem'] as Map<String, dynamic>)
          : const CoordinateFrame(),
      room: RoomGeometry.fromJson(json['room'] as Map<String, dynamic>? ?? {}),
      wifi: WifiDataset.fromJson(json['wifi'] as Map<String, dynamic>? ?? {}),
      quality: json['quality'] != null
          ? QualityMetrics.fromJson(json['quality'] as Map<String, dynamic>)
          : const QualityMetrics(),
    );
  }
}
