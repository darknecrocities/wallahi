import 'dart:math' as math;

/// 2D Cartesian vector representing coordinates in the metric XZ floor plane.
class Vec2 {
  final double x;
  final double z;

  const Vec2(this.x, this.z);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, z + other.z);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, z - other.z);
  Vec2 operator *(double scalar) => Vec2(x * scalar, z * scalar);
  Vec2 operator /(double scalar) => Vec2(x / scalar, z / scalar);

  double dot(Vec2 other) => x * other.x + z * other.z;
  double cross(Vec2 other) => x * other.z - z * other.x;
  double get lengthSquared => x * x + z * z;
  double get length => math.sqrt(lengthSquared);

  Vec2 normalized() {
    final len = length;
    if (len < 1e-9) return const Vec2(0, 0);
    return Vec2(x / len, z / len);
  }

  double distanceTo(Vec2 other) => (this - other).length;
}

/// 3D metric vector aligned with Wallahi frame (+Y up, XZ ground plane).
class Vec3 {
  final double x;
  final double y;
  final double z;

  const Vec3(this.x, this.y, this.z);

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);
  Vec3 operator *(double scalar) =>
      Vec3(x * scalar, y * scalar, z * scalar);

  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;
  double get length => math.sqrt(x * x + y * y + z * z);
  double distanceTo(Vec3 other) => (this - other).length;

  Vec2 toFloorPlane() => Vec2(x, z);
}

/// 2D Axis-Aligned Bounding Box (AABB) in floor plane coordinates.
class BoundingBox2D {
  final double minX;
  final double maxX;
  final double minZ;
  final double maxZ;

  const BoundingBox2D({
    required this.minX,
    required this.maxX,
    required this.minZ,
    required this.maxZ,
  });

  bool contains(Vec2 point) {
    return point.x >= minX &&
        point.x <= maxX &&
        point.z >= minZ &&
        point.z <= maxZ;
  }

  double get width => maxX - minX;
  double get depth => maxZ - minZ;
}
