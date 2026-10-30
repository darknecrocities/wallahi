import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geometry/geometry.dart';
import 'package:room_format/room_format.dart';
import 'package:sensor_fusion/sensor_fusion.dart';
import '../../core/constants/app_colors.dart';
import '../analysis/project_detail_screen.dart';
import 'scan_controller.dart';

/// Interactive guided AR camera & Wi-Fi scanning workflow screen.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Main Office Space');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _simulateScanSteps() {
    final notifier = ref.read(scanControllerProvider.notifier);
    notifier.startSession(_nameController.text);

    // Simulate ground detection
    notifier.onFloorDetected(
      const FloorPolygon(vertices: [
        FloorPoint(x: 0, z: 0),
        FloorPoint(x: 5, z: 0),
        FloorPoint(x: 5, z: 4),
        FloorPoint(x: 0, z: 4),
      ]),
    );

    // Simulate keyframe trajectory
    final now = DateTime.now().millisecondsSinceEpoch;
    notifier.addPoseKeyframe(ArPoseKeyframe(
      timestampMs: now,
      position: const Vec3(0, 1.2, 0),
      rotation: (0, 0, 0, 1),
    ));
    notifier.addPoseKeyframe(ArPoseKeyframe(
      timestampMs: now + 300,
      position: const Vec3(2.5, 1.2, 2.0),
      rotation: (0, 0, 0, 1),
    ));
    notifier.addPoseKeyframe(ArPoseKeyframe(
      timestampMs: now + 600,
      position: const Vec3(4.5, 1.2, 3.5),
      rotation: (0, 0, 0, 1),
    ));

    // Simulate Wi-Fi measurements
    notifier.addWifiPacket(RawWifiPacket(
      timestampMs: now + 350,
      bssid: 'aa:bb:cc:dd:ee:11',
      ssid: 'Wallahi-Mesh-5G',
      rssiDbm: -52,
      frequencyMhz: 5200,
      rttDistanceMeters: 2.8,
      rttStdDevMeters: 0.6,
    ));

    // Simulate detected walls
    notifier.addDetectedWall(const WallModel(
      id: 'w1',
      startX: 0,
      startZ: 0,
      endX: 5,
      endZ: 0,
    ));
    notifier.addDetectedWall(const WallModel(
      id: 'w2',
      startX: 5,
      startZ: 0,
      endX: 5,
      endZ: 4,
    ));
    notifier.addDetectedWall(const WallModel(
      id: 'w3',
      startX: 5,
      startZ: 4,
      endX: 0,
      endZ: 4,
    ));
    notifier.addDetectedWall(const WallModel(
      id: 'w4',
      startX: 0,
      startZ: 4,
      endX: 0,
      endZ: 0,
    ));

    notifier.finalizeScan();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Spatial AR + Wi-Fi Scanner'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surfaceElevated,
              child: Row(
                children: [
                  const Icon(Icons.radar, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scanState.statusMessage,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Viewfinder Simulated Preview Area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            scanState.step == ScanStep.scanning
                                ? Icons.view_in_ar
                                : Icons.camera_alt_outlined,
                            size: 64,
                            color: AppColors.accent.withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            scanState.step == ScanStep.idle
                                ? 'Tap "Start Scan" to initiate AR tracking'
                                : 'Scanning Active: ${scanState.roomName}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (scanState.trajectory.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Trajectory Poses: ${scanState.trajectory.length} | Wi-Fi Samples: ${scanState.rawPackets.length}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Control Actions Panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (scanState.step == ScanStep.idle) ...[
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Room Name',
                        labelStyle: TextStyle(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.room, color: AppColors.accent),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _simulateScanSteps,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'Start Spatial Scan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ] else if (scanState.step == ScanStep.reviewing &&
                      scanState.resultProject != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(
                                project: scanState.resultProject!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.map),
                        label: const Text(
                          'View Floor Plan & RF Map',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
