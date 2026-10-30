"""Point-cloud processing, Statistical Outlier Removal (SOR), and RANSAC plane segmentation."""

from dataclasses import dataclass
import math
from typing import List, Tuple
import numpy as np


@dataclass
class PlaneModel:
    a: float
    b: float
    c: float
    d: float

    @property
    def normal(self) -> np.ndarray:
        return np.array([self.a, self.b, self.c])


class PointCloudProcessor:
    """Processes 3D spatial points with outlier rejection and RANSAC planar fitting."""

    def __init__(self, sor_k_neighbors: int = 16, sor_std_ratio: float = 1.8):
        self.sor_k_neighbors = sor_k_neighbors
        self.sor_std_ratio = sor_std_ratio

    def filter_statistical_outliers(self, points: np.ndarray) -> np.ndarray:
        """Removes floating noise points using distance-to-neighbor statistics."""
        if len(points) < self.sor_k_neighbors:
            return points

        # Compute pairwise distances for small point clouds
        n = len(points)
        dists = np.zeros(n)
        for i in range(n):
            diff = points - points[i]
            d = np.linalg.norm(diff, axis=1)
            d.sort()
            # Mean distance to k nearest neighbors (excluding self at index 0)
            k = min(self.sor_k_neighbors, n - 1)
            dists[i] = np.mean(d[1 : k + 1])

        mean_dist = np.mean(dists)
        std_dist = np.std(dists)
        threshold = mean_dist + self.sor_std_ratio * std_dist

        inliers = points[dists <= threshold]
        return inliers

    def fit_plane_ransac(
        self,
        points: np.ndarray,
        distance_threshold: float = 0.05,
        max_iterations: int = 100,
    ) -> Tuple[PlaneModel, np.ndarray]:
        """Fits best plane ax + by + cz + d = 0 via RANSAC."""
        if len(points) < 3:
            return PlaneModel(0, 1, 0, 0), np.array([], dtype=int)

        best_inliers: List[int] = []
        best_plane = PlaneModel(0, 1, 0, 0)
        n = len(points)

        rng = np.random.default_rng(42)

        for _ in range(max_iterations):
            sample_indices = rng.choice(n, size=3, replace=False)
            p1, p2, p3 = points[sample_indices]

            v1 = p2 - p1
            v2 = p3 - p1
            normal = np.cross(v1, v2)
            norm = np.linalg.norm(normal)
            if norm < 1e-7:
                continue

            normal = normal / norm
            d = -np.dot(normal, p1)

            # Distance from all points to plane: |ax + by + cz + d|
            distances = np.abs(np.dot(points, normal) + d)
            inlier_indices = np.where(distances <= distance_threshold)[0]

            if len(inlier_indices) > len(best_inliers):
                best_inliers = inlier_indices.tolist()
                best_plane = PlaneModel(
                    float(normal[0]), float(normal[1]), float(normal[2]), float(d)
                )

        return best_plane, np.array(best_inliers, dtype=int)
