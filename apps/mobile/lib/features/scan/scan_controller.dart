import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geometry/geometry.dart';
import 'package:room_format/room_format.dart';
import 'package:sensor_fusion/sensor_fusion.dart';

enum ScanStep {
  idle,
  calibrating,
  scanning,
  fusing,
  reviewing,
  completed,
}

class ScanState {
  final ScanStep step;
  final String roomName;
  final List<ArPoseKeyframe> trajectory;
  final List<RawWifiPacket> rawPackets;
  final List<WallModel> detectedWalls;
  final FloorPolygon? floorBoundary;
  final RoomProject? resultProject;
  final String statusMessage;

  const ScanState({
    this.step = ScanStep.idle,
    this.roomName = 'New Room',
    this.trajectory = const [],
    this.rawPackets = const [],
    this.detectedWalls = const [],
    this.floorBoundary,
    this.resultProject,
    this.statusMessage = 'Ready to initiate scan',
  });

  ScanState copyWith({
    ScanStep? step,
    String? roomName,
    List<ArPoseKeyframe>? trajectory,
    List<RawWifiPacket>? rawPackets,
    List<WallModel>? detectedWalls,
    FloorPolygon? floorBoundary,
    RoomProject? resultProject,
    String? statusMessage,
  }) {
    return ScanState(
      step: step ?? this.step,
      roomName: roomName ?? this.roomName,
      trajectory: trajectory ?? this.trajectory,
      rawPackets: rawPackets ?? this.rawPackets,
      detectedWalls: detectedWalls ?? this.detectedWalls,
      floorBoundary: floorBoundary ?? this.floorBoundary,
      resultProject: resultProject ?? this.resultProject,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class ScanController extends StateNotifier<ScanState> {
  final SensorFusionPipeline fusionPipeline;
  final WallSnappingEngine wallSnapper;

  ScanController({
    this.fusionPipeline = const SensorFusionPipeline(),
    this.wallSnapper = const WallSnappingEngine(),
  }) : super(const ScanState());

  void startSession(String roomName) {
    state = state.copyWith(
      step: ScanStep.calibrating,
      roomName: roomName,
      trajectory: [],
      rawPackets: [],
      detectedWalls: [],
      floorBoundary: null,
      resultProject: null,
      statusMessage: 'Point camera at floor to initialize spatial anchor...',
    );
  }

  void onFloorDetected(FloorPolygon boundary) {
    state = state.copyWith(
      step: ScanStep.scanning,
      floorBoundary: boundary,
      statusMessage: 'Floor plane locked. Slowly traverse perimeter.',
    );
  }

  void addPoseKeyframe(ArPoseKeyframe keyframe) {
    if (state.step != ScanStep.scanning) return;
    state = state.copyWith(
      trajectory: [...state.trajectory, keyframe],
    );
  }

  void addWifiPacket(RawWifiPacket packet) {
    if (state.step != ScanStep.scanning) return;
    state = state.copyWith(
      rawPackets: [...state.rawPackets, packet],
    );
  }

  void addDetectedWall(WallModel wall) {
    if (state.step != ScanStep.scanning) return;
    state = state.copyWith(
      detectedWalls: [...state.detectedWalls, wall],
    );
  }

  void finalizeScan() {
    if (state.step != ScanStep.scanning) return;
    state = state.copyWith(
      step: ScanStep.fusing,
      statusMessage: 'Aligning sensors and computing spatial RF heatmap...',
    );

    // Regularize walls using snapping engine
    final wallSegments = state.detectedWalls
        .map((w) => WallSegment2D(
              id: w.id,
              start: Vec2(w.startX, w.startZ),
              end: Vec2(w.endX, w.endZ),
              height: w.heightMeters,
              thickness: w.thicknessMeters,
            ))
        .toList();

    final snappedSegments = wallSegments.map(wallSnapper.snapToOrthogonal).toList();
    final connectedSegments = wallSnapper.snapCorners(snappedSegments);

    final finalWalls = connectedSegments
        .map((s) => WallModel(
              id: s.id,
              startX: s.start.x,
              startZ: s.start.z,
              endX: s.end.x,
              endZ: s.end.z,
              heightMeters: s.height,
              thicknessMeters: s.thickness,
            ))
        .toList();

    final floor = state.floorBoundary ??
        const FloorPolygon(vertices: [
          FloorPoint(x: 0, z: 0),
          FloorPoint(x: 5, z: 0),
          FloorPoint(x: 5, z: 5),
          FloorPoint(x: 0, z: 5),
        ]);

    final project = fusionPipeline.fuseProject(
      projectId: 'proj-${DateTime.now().millisecondsSinceEpoch}',
      roomName: state.roomName,
      trajectory: state.trajectory,
      rawPackets: state.rawPackets,
      walls: finalWalls,
      floorBoundary: floor,
    );

    state = state.copyWith(
      step: ScanStep.reviewing,
      resultProject: project,
      statusMessage: 'Scan complete. Review geometry and coverage.',
    );
  }

  void reset() {
    state = const ScanState();
  }
}

final scanControllerProvider =
    StateNotifierProvider<ScanController, ScanState>((ref) {
  return ScanController();
});
