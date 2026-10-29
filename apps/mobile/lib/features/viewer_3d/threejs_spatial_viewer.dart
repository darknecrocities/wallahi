import 'dart:convert';
import 'package:room_format/room_format.dart';

/// WebGL 3D Spatial Viewer HTML generator embedding Three.js PBR rendering.
class ThreeJsSpatialViewerGenerator {
  /// Generates self-contained HTML/WebGL bundle visualizing 3D room and Wi-Fi fields.
  static String generateHtml(RoomProject project) {
    final projectJson = jsonEncode(project.toJson());

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>Wallahi 3D Spatial Viewer</title>
  <style>
    body { margin: 0; padding: 0; overflow: hidden; background: #0F172A; font-family: sans-serif; }
    #canvas-container { width: 100vw; height: 100vh; display: block; }
    #hud {
      position: absolute; top: 12px; left: 12px;
      color: #F8FAFC; background: rgba(30, 41, 59, 0.85);
      padding: 10px 14px; border-radius: 8px; border: 1px solid #475569;
      font-size: 13px; pointer-events: none;
    }
  </style>
  <script src="https://unpkg.com/three@0.160.0/build/three.min.js"></script>
  <script src="https://unpkg.com/three@0.160.0/examples/js/controls/OrbitControls.js"></script>
</head>
<body>
  <div id="hud">
    <strong>Wallahi 3D Spatial Model</strong><br>
    Room: ${project.name}<br>
    Walls: ${project.room.walls.length} | APs: ${project.wifi.accessPoints.length}
  </div>
  <div id="canvas-container"></div>

  <script>
    const data = $projectJson;
    const container = document.getElementById('canvas-container');

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0F172A);
    scene.fog = new THREE.FogExp2(0x0F172A, 0.05);

    const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 100);
    camera.position.set(0, 7, 8);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.shadowMap.enabled = true;
    container.appendChild(renderer.domElement);

    const controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;

    // Studio Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);
    const dirLight = new THREE.DirectionalLight(0xffffff, 0.8);
    dirLight.position.set(5, 10, 5);
    dirLight.castShadow = true;
    scene.add(dirLight);

    // Grid Floor
    const gridHelper = new THREE.GridHelper(20, 20, 0x475569, 0x1E293B);
    scene.add(gridHelper);

    // Extrude Walls
    const wallMaterial = new THREE.MeshStandardMaterial({
      color: 0x94A3B8,
      roughness: 0.4,
      metalness: 0.1,
      side: THREE.DoubleSide
    });

    data.room.walls.forEach(w => {
      const dx = w.endX - w.startX;
      const dz = w.endZ - w.startZ;
      const len = Math.sqrt(dx * dx + dz * dz);
      const angle = Math.atan2(dz, dx);

      const wallGeo = new THREE.BoxGeometry(len, w.heightMeters, w.thicknessMeters);
      const mesh = new THREE.Mesh(wallGeo, wallMaterial);
      mesh.position.set(
        (w.startX + w.endX) / 2,
        w.heightMeters / 2,
        (w.startZ + w.endZ) / 2
      );
      mesh.rotation.y = -angle;
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      scene.add(mesh);
    });

    // Render Wi-Fi Heatmap Points
    if (data.wifi.heatmap && data.wifi.heatmap.cells) {
      data.wifi.heatmap.cells.forEach(c => {
        const norm = Math.min(1.0, Math.max(0.0, (c.rssiDbm - (-90)) / 55));
        const color = new THREE.Color().setHSL(0.33 * norm, 1.0, 0.5);
        const cellGeo = new THREE.PlaneGeometry(data.wifi.heatmap.resolutionMeters * 0.9, data.wifi.heatmap.resolutionMeters * 0.9);
        const cellMat = new THREE.MeshBasicMaterial({
          color: color,
          transparent: true,
          opacity: 0.75 * (1.0 - (c.uncertainty || 0) * 0.6),
          side: THREE.DoubleSide
        });
        const cellMesh = new THREE.Mesh(cellGeo, cellMat);
        cellMesh.rotation.x = -Math.PI / 2;
        cellMesh.position.set(c.x, 0.02, c.z);
        scene.add(cellMesh);
      });
    }

    // Access Point Beacons
    data.wifi.accessPoints.forEach(ap => {
      if (ap.estimatedPosition) {
        const beaconGeo = new THREE.SphereGeometry(0.25, 16, 16);
        const beaconMat = new THREE.MeshStandardMaterial({ color: 0x38BDF8, emissive: 0x0284C7 });
        const beacon = new THREE.Mesh(beaconGeo, beaconMat);
        beacon.position.set(ap.estimatedPosition.x, ap.estimatedPosition.y || 1.8, ap.estimatedPosition.z);
        scene.add(beacon);
      }
    });

    function animate() {
      requestAnimationFrame(animate);
      controls.update();
      renderer.render(scene, camera);
    }
    animate();

    window.addEventListener('resize', () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    });
  </script>
</body>
</html>
''';
  }
}
