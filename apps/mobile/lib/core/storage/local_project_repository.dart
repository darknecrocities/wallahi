import 'dart:convert';
import 'dart:io';
import 'package:room_format/room_format.dart';

/// Offline-first file repository persisting projects to local storage directory.
class LocalProjectRepository {
  final Directory storageDirectory;

  LocalProjectRepository({required this.storageDirectory}) {
    if (!storageDirectory.existsSync()) {
      storageDirectory.createSync(recursive: true);
    }
  }

  File _getProjectFile(String projectId) {
    return File('${storageDirectory.path}/$projectId.wallahi.json');
  }

  /// Saves a [RoomProject] as a normalized JSON file.
  Future<void> saveProject(RoomProject project) async {
    final file = _getProjectFile(project.projectId);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(project.toJson());
    await file.writeAsString(jsonStr, flush: true);
  }

  /// Loads a [RoomProject] by its [projectId].
  Future<RoomProject?> loadProject(String projectId) async {
    final file = _getProjectFile(projectId);
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    final jsonMap = jsonDecode(content) as Map<String, dynamic>;
    return RoomProject.fromJson(jsonMap);
  }

  /// Lists all stored projects in the repository.
  Future<List<RoomProject>> listAllProjects() async {
    final List<RoomProject> projects = [];
    if (!await storageDirectory.exists()) return projects;

    final entities = storageDirectory.listSync();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.wallahi.json')) {
        try {
          final content = await entity.readAsString();
          final jsonMap = jsonDecode(content) as Map<String, dynamic>;
          projects.add(RoomProject.fromJson(jsonMap));
        } catch (_) {
          // Skip corrupt or unreadable files gracefully
        }
      }
    }

    projects.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return projects;
  }

  /// Deletes a project file.
  Future<bool> deleteProject(String projectId) async {
    final file = _getProjectFile(projectId);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }
}
