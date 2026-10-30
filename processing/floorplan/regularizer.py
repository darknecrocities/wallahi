"""Floorplan orthogonal regularization and loop closure module."""

from dataclasses import dataclass
import math
from typing import List, Tuple


@dataclass
class Wall2D:
    wall_id: str
    start_x: float
    start_z: float
    end_x: float
    end_z: float
    height_m: float = 2.8


class FloorplanRegularizer:
    """Snaps room walls to orthogonal axes and resolves loop closure gaps."""

    def __init__(self, angle_tolerance_deg: float = 12.0, snap_dist_m: float = 0.25):
        self.angle_tolerance_rad = math.radians(angle_tolerance_deg)
        self.snap_dist_m = snap_dist_m

    def snap_orthogonal(self, wall: Wall2D) -> Wall2D:
        """Snaps wall angle to nearest 0, 90, 180, 270 degrees if within tolerance."""
        dx = wall.end_x - wall.start_x
        dz = wall.end_z - wall.start_z
        length = math.hypot(dx, dz)
        if length < 1e-6:
            return wall

        angle = math.atan2(dz, dx)
        target_angles = [-math.pi, -math.pi / 2, 0.0, math.pi / 2, math.pi]

        closest_target = angle
        min_diff = float("inf")
        for target in target_angles:
            diff = abs(angle - target)
            if diff < min_diff and diff <= self.angle_tolerance_rad:
                min_diff = diff
                closest_target = target

        if min_diff > self.angle_tolerance_rad:
            return wall

        new_end_x = wall.start_x + length * math.cos(closest_target)
        new_end_z = wall.start_z + length * math.sin(closest_target)

        return Wall2D(
            wall_id=wall.wall_id,
            start_x=wall.start_x,
            start_z=wall.start_z,
            end_x=new_end_x,
            end_z=new_end_z,
            height_m=wall.height_m,
        )

    def close_loops(self, walls: List[Wall2D]) -> List[Wall2D]:
        """Merges adjacent endpoints within tolerance to guarantee perimeter closure."""
        if len(walls) < 2:
            return walls

        res = [Wall2D(**w.__dict__) for w in walls]
        n = len(res)

        for i in range(n):
            next_idx = (i + 1) % n
            w1 = res[i]
            w2 = res[next_idx]

            gap = math.hypot(w1.end_x - w2.start_x, w1.end_z - w2.start_z)
            if gap <= self.snap_dist_m:
                mid_x = (w1.end_x + w2.start_x) / 2.0
                mid_z = (w1.end_z + w2.start_z) / 2.0
                w1.end_x = mid_x
                w1.end_z = mid_z
                w2.start_x = mid_x
                w2.start_z = mid_z

        return res
