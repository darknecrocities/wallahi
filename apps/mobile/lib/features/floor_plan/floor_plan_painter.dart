import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:room_format/room_format.dart';
import '../../core/constants/app_colors.dart';

/// Hardware-accelerated CustomPainter rendering 2D floor plan with RF heatmap layer.
class FloorPlanPainter extends CustomPainter {
  final RoomProject project;
  final bool showHeatmap;
  final bool showUncertainty;
  final bool showAccessPoints;
  final double zoomScale;
  final Offset panOffset;

  FloorPlanPainter({
    required this.project,
    this.showHeatmap = true,
    this.showUncertainty = true,
    this.showAccessPoints = true,
    this.zoomScale = 45.0, // pixels per meter
    this.panOffset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2.0 + panOffset.dx, size.height / 2.0 + panOffset.dy);

    _drawGridBackground(canvas, size);
    _drawFloorBoundary(canvas);
    if (showHeatmap) _drawHeatmap(canvas);
    _drawWalls(canvas);
    if (showAccessPoints) _drawAccessPoints(canvas);
    _drawScaleBar(canvas, size);

    canvas.restore();
  }

  void _drawGridBackground(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const step = 1.0; // 1-meter grid lines
    final span = (math.max(size.width, size.height) / zoomScale) + 5.0;

    for (double x = -span; x <= span; x += step) {
      canvas.drawLine(
        Offset(x * zoomScale, -span * zoomScale),
        Offset(x * zoomScale, span * zoomScale),
        gridPaint,
      );
    }
    for (double z = -span; z <= span; z += step) {
      canvas.drawLine(
        Offset(-span * zoomScale, z * zoomScale),
        Offset(span * zoomScale, z * zoomScale),
        gridPaint,
      );
    }
  }

  void _drawFloorBoundary(Canvas canvas) {
    final vertices = project.room.floorBoundary.vertices;
    if (vertices.length < 3) return;

    final path = Path();
    path.moveTo(vertices.first.x * zoomScale, vertices.first.z * zoomScale);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].x * zoomScale, vertices[i].z * zoomScale);
    }
    path.close();

    final fillPaint = Paint()
      ..color = AppColors.surface.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  void _drawHeatmap(Canvas canvas) {
    final heatmap = project.wifi.heatmap;
    if (heatmap == null || heatmap.cells.isEmpty) return;

    final cellHalfSize = (heatmap.resolutionMeters / 2.0) * zoomScale;

    for (final cell in heatmap.cells) {
      final center = Offset(cell.x * zoomScale, cell.z * zoomScale);
      final opacity = showUncertainty
          ? (1.0 - cell.uncertainty * 0.7).clamp(0.2, 0.9)
          : 0.85;

      final color = AppColors.rssiToColor(cell.rssiDbm, opacity: opacity);
      final cellPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: center,
          width: cellHalfSize * 2.0,
          height: cellHalfSize * 2.0,
        ),
        cellPaint,
      );
    }
  }

  void _drawWalls(Canvas canvas) {
    final wallPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (final wall in project.room.walls) {
      final p1 = Offset(wall.startX * zoomScale, wall.startZ * zoomScale);
      final p2 = Offset(wall.endX * zoomScale, wall.endZ * zoomScale);
      canvas.drawLine(p1, p2, wallPaint);
    }
  }

  void _drawAccessPoints(Canvas canvas) {
    final apPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    for (final ap in project.wifi.accessPoints) {
      if (ap.estimatedPosX == null || ap.estimatedPosZ == null) continue;
      final center = Offset(
        ap.estimatedPosX! * zoomScale,
        ap.estimatedPosZ! * zoomScale,
      );

      canvas.drawCircle(center, 7.0, apPaint);
      canvas.drawCircle(
        center,
        12.0,
        Paint()
          ..color = AppColors.accent.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  void _drawScaleBar(Canvas canvas, Size size) {
    final scaleLengthPx = 1.0 * zoomScale; // 1 meter scale bar
    final barPaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 3.0;

    final start = Offset(-size.width / 2.0 + 20, size.height / 2.0 - 30);
    final end = Offset(start.dx + scaleLengthPx, start.dy);

    canvas.drawLine(start, end, barPaint);
    canvas.drawLine(start, Offset(start.dx, start.dy - 6), barPaint);
    canvas.drawLine(end, Offset(end.dx, end.dy - 6), barPaint);
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.project != project ||
        oldDelegate.showHeatmap != showHeatmap ||
        oldDelegate.showUncertainty != showUncertainty ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.panOffset != panOffset;
  }
}
