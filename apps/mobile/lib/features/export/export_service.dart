import 'dart:convert';
import 'package:room_format/room_format.dart';

/// Formatter and exporter converting Wallahi projects into standard industrial interchange formats.
class ExportService {
  /// Exports canonical project to pretty-printed JSON.
  static String exportToJson(RoomProject project) {
    return const JsonEncoder.withIndent('  ').convert(project.toJson());
  }

  /// Exports room boundaries and Wi-Fi access points to GeoJSON format.
  static String exportToGeoJson(RoomProject project) {
    final features = <Map<String, dynamic>>[];

    // Floor Polygon Feature
    if (project.room.floorBoundary.vertices.isNotEmpty) {
      final coordinates = project.room.floorBoundary.vertices
          .map((v) => [v.x, v.z])
          .toList();
      coordinates.add([
        project.room.floorBoundary.vertices.first.x,
        project.room.floorBoundary.vertices.first.z,
      ]);

      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [coordinates],
        },
        'properties': {
          'type': 'floor_boundary',
          'room_name': project.name,
          'area_sqm': project.room.floorBoundary.areaSquareMeters,
        },
      });
    }

    // Access Point Features
    for (final ap in project.wifi.accessPoints) {
      if (ap.estimatedPosX == null || ap.estimatedPosZ == null) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [ap.estimatedPosX, ap.estimatedPosZ],
        },
        'properties': {
          'bssid': ap.bssid,
          'ssid': ap.ssid,
          'channel': ap.channel,
          'frequencyMhz': ap.frequencyMhz,
        },
      });
    }

    final geoJsonMap = {
      'type': 'FeatureCollection',
      'features': features,
    };

    return const JsonEncoder.withIndent('  ').convert(geoJsonMap);
  }

  /// Exports 3D extruded walls as Wavefront OBJ format.
  static String exportToObj(RoomProject project) {
    final buffer = StringBuffer();
    buffer.writeln('# Wallahi 3D Room Model Export');
    buffer.writeln('# Project: ${project.name} (${project.projectId})');
    buffer.writeln('# Units: meters');

    int vertexIndex = 1;

    for (final wall in project.room.walls) {
      final h = wall.heightMeters;
      // 4 corners of the vertical rectangular wall
      buffer.writeln('v ${wall.startX} 0.0 ${wall.startZ}');
      buffer.writeln('v ${wall.endX} 0.0 ${wall.endZ}');
      buffer.writeln('v ${wall.endX} $h ${wall.endZ}');
      buffer.writeln('v ${wall.startX} $h ${wall.startZ}');

      // Two triangles forming the quad face
      buffer.writeln('f $vertexIndex ${vertexIndex + 1} ${vertexIndex + 2}');
      buffer.writeln('f $vertexIndex ${vertexIndex + 2} ${vertexIndex + 3}');
      vertexIndex += 4;
    }

    return buffer.toString();
  }
}
