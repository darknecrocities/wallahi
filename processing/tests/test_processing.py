"""Unit tests for Python floorplan regularizer, point cloud filter, and benchmark evaluator."""

import math
import unittest
import numpy as np

from processing.floorplan.regularizer import FloorplanRegularizer, Wall2D
from processing.open3d.pointcloud_processor import PointCloudProcessor
from processing.evaluation.benchmark_evaluator import BenchmarkEvaluator


class TestProcessingPipeline(unittest.TestCase):
    def test_floorplan_regularizer_orthogonal_snap(self):
        reg = FloorplanRegularizer(angle_tolerance_deg=15.0)

        # Wall angled at 86 degrees (should snap to 90 degrees)
        rad = math.radians(86)
        wall = Wall2D(
            wall_id="w-slanted",
            start_x=0.0,
            start_z=0.0,
            end_x=4.0 * math.cos(rad),
            end_z=4.0 * math.sin(rad),
        )

        snapped = reg.snap_orthogonal(wall)
        snapped_angle = math.degrees(
            math.atan2(snapped.end_z - snapped.start_z, snapped.end_x - snapped.start_x)
        )
        self.assertAlmostEqual(snapped_angle, 90.0, places=2)
        self.assertAlmostEqual(snapped.end_x, 0.0, places=2)
        self.assertAlmostEqual(snapped.end_z, 4.0, places=2)

    def test_floorplan_regularizer_loop_closure(self):
        reg = FloorplanRegularizer(snap_dist_m=0.20)
        # Wall 1 ends at (5.0, 0.0), Wall 2 starts at (5.08, 0.0) -> gap of 0.08m
        walls = [
            Wall2D("w1", 0.0, 0.0, 5.0, 0.0),
            Wall2D("w2", 5.08, 0.0, 5.08, 4.0),
        ]
        closed = reg.close_loops(walls)
        self.assertAlmostEqual(closed[0].end_x, closed[1].start_x, places=3)
        self.assertAlmostEqual(closed[0].end_x, 5.04, places=2)

    def test_pointcloud_ransac_plane_fit(self):
        proc = PointCloudProcessor()

        # Create 100 points on horizontal plane y = 0 with small noise
        rng = np.random.default_rng(42)
        x = rng.uniform(-5, 5, 100)
        z = rng.uniform(-5, 5, 100)
        y = rng.normal(0.0, 0.01, 100)
        points = np.column_stack([x, y, z])

        plane, inliers = proc.fit_plane_ransac(points, distance_threshold=0.05)
        # Normal should be approximately (0, 1, 0)
        self.assertGreater(len(inliers), 90)
        self.assertAlmostEqual(abs(plane.b), 1.0, delta=0.05)

    def test_benchmark_evaluator_geometry_and_rf(self):
        evaluator = BenchmarkEvaluator()

        walls = [
            (0.0, 0.0, 4.02, 0.0),  # Est: 4.02, GT: 4.0 -> error 0.02
            (4.02, 0.0, 4.02, 3.0),  # Est: 3.00, GT: 3.0 -> error 0.00
        ]
        gt_lengths = [4.0, 3.0]

        geo_res = evaluator.evaluate_geometry(walls, gt_lengths)
        self.assertAlmostEqual(geo_res.mean_wde_meters, 0.01, places=2)

        # Test RF Cross-Validation
        rf_samples = [
            (0.0, 0.0, -40.0),
            (2.0, 0.0, -55.0),
            (4.0, 0.0, -70.0),
            (1.0, 2.0, -60.0),
            (3.0, 2.0, -65.0),
            (0.0, 4.0, -75.0),
        ]
        rf_res = evaluator.evaluate_rf_cross_validation(rf_samples, holdout_fraction=0.3)
        self.assertGreater(rf_res.test_sample_count, 0)
        self.assertGreater(rf_res.holdout_rmse_dbm, 0.0)


if __name__ == "__main__":
    unittest.main()
