import 'package:flutter/material.dart';
import 'package:room_format/room_format.dart';
import '../../core/constants/app_colors.dart';
import '../export/export_service.dart';
import '../floor_plan/floor_plan_painter.dart';

/// Detailed inspection screen rendering 2D floor plan, RF heatmaps, and export options.
class ProjectDetailScreen extends StatefulWidget {
  final RoomProject project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool _showHeatmap = true;
  bool _showUncertainty = true;
  bool _showAccessPoints = true;
  double _zoomScale = 45.0;
  Offset _panOffset = Offset.zero;

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Spatial Project',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.code, color: AppColors.accent),
                title: const Text('Normalized JSON (.wallahi.json)',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Complete portable model with raw samples',
                    style: TextStyle(color: AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  final json = ExportService.exportToJson(widget.project);
                  _showExportSnippetDialog('Normalized JSON', json);
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: AppColors.success),
                title: const Text('GeoJSON (.geojson)',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('GIS compatible polygon & AP coordinates',
                    style: TextStyle(color: AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  final geoJson = ExportService.exportToGeoJson(widget.project);
                  _showExportSnippetDialog('GeoJSON', geoJson);
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_in_ar, color: AppColors.warning),
                title: const Text('Wavefront OBJ (.obj)',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('3D CAD mesh with extruded walls',
                    style: TextStyle(color: AppColors.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  final obj = ExportService.exportToObj(widget.project);
                  _showExportSnippetDialog('Wavefront OBJ', obj);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportSnippetDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.project.room.floorBoundary.areaSquareMeters;
    final wallCount = widget.project.room.walls.length;
    final apCount = widget.project.wifi.accessPoints.length;
    final confidence =
        (widget.project.quality.wifiCoverageConfidence * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.project.name),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Project',
            onPressed: _showExportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Metrics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surfaceElevated,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricItem('Floor Area', '${area.toStringAsFixed(1)} m²'),
                _metricItem('Walls', '$wallCount'),
                _metricItem('Access Points', '$apCount'),
                _metricItem('RF Confidence', '$confidence%'),
              ],
            ),
          ),

          // Interactive 2D Canvas with Pan and Zoom
          Expanded(
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _zoomScale = (_zoomScale * details.scale).clamp(15.0, 150.0);
                  _panOffset += details.focalPointDelta;
                });
              },
              child: ClipRect(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: FloorPlanPainter(
                    project: widget.project,
                    showHeatmap: _showHeatmap,
                    showUncertainty: _showUncertainty,
                    showAccessPoints: _showAccessPoints,
                    zoomScale: _zoomScale,
                    panOffset: _panOffset,
                  ),
                ),
              ),
            ),
          ),

          // Layer Control Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilterChip(
                  label: const Text('RF Heatmap'),
                  selected: _showHeatmap,
                  onSelected: (val) => setState(() => _showHeatmap = val),
                  selectedColor: AppColors.accent.withOpacity(0.3),
                  checkmarkColor: AppColors.accent,
                ),
                FilterChip(
                  label: const Text('Uncertainty'),
                  selected: _showUncertainty,
                  onSelected: (val) => setState(() => _showUncertainty = val),
                  selectedColor: AppColors.warning.withOpacity(0.3),
                  checkmarkColor: AppColors.warning,
                ),
                FilterChip(
                  label: const Text('Access Points'),
                  selected: _showAccessPoints,
                  onSelected: (val) => setState(() => _showAccessPoints = val),
                  selectedColor: AppColors.success.withOpacity(0.3),
                  checkmarkColor: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
