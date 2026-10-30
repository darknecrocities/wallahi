"""Benchmark evaluation suite measuring CV geometry errors and RF heatmap RMSE."""

from dataclasses import dataclass
import math
from typing import Dict, List, Tuple
import numpy as np


@dataclass
class GeometricBenchmarkResult:
    mean_wde_meters: float
    max_wde_meters: float
    loop_closure_error_meters: float
    mean_orthogonality_dev_deg: float


@dataclass
class RfCrossValidationResult:
    holdout_rmse_dbm: float
    mean_absolute_error_dbm: float
    test_sample_count: int


class BenchmarkEvaluator:
    """Evaluates spatial mapping accuracy against ground truth references."""

    @staticmethod
    def evaluate_geometry(
        estimated_walls: List[Tuple[float, float, float, float]],
        ground_truth_lengths: List[float],
    ) -> GeometricBenchmarkResult:
        """Compares estimated wall segments with laser ground truth lengths."""
        if not estimated_walls:
            return GeometricBenchmarkResult(0.0, 0.0, 0.0, 0.0)

        errors = []
        for (sx, sz, ex, ez), gt_len in zip(estimated_walls, ground_truth_lengths):
            est_len = math.hypot(ex - sx, ez - sz)
            errors.append(abs(est_len - gt_len))

        mean_wde = float(np.mean(errors)) if errors else 0.0
        max_wde = float(np.max(errors)) if errors else 0.0

        # Loop closure: distance between end of last wall and start of first wall
        first_sx, first_sz = estimated_walls[0][0], estimated_walls[0][1]
        last_ex, last_ez = estimated_walls[-1][2], estimated_walls[-1][3]
        lce = math.hypot(last_ex - first_sx, last_ez - first_sz)

        # Angle deviation from orthogonal (0, 90, 180, 270)
        angle_devs = []
        for sx, sz, ex, ez in estimated_walls:
            deg = math.degrees(math.atan2(ez - sz, ex - sx)) % 90.0
            dev = min(deg, 90.0 - deg)
            angle_devs.append(dev)

        mean_ortho = float(np.mean(angle_devs)) if angle_devs else 0.0

        return GeometricBenchmarkResult(
            mean_wde_meters=round(mean_wde, 4),
            max_wde_meters=round(max_wde, 4),
            loop_closure_error_meters=round(lce, 4),
            mean_orthogonality_dev_deg=round(mean_ortho, 2),
        )

    @staticmethod
    def evaluate_rf_cross_validation(
        samples: List[Tuple[float, float, float]],  # (x, z, rssi_dbm)
        holdout_fraction: float = 0.20,
    ) -> RfCrossValidationResult:
        """Performs Leave-K-Out spatial cross-validation on IDW interpolated fields."""
        if len(samples) < 5:
            return RfCrossValidationResult(0.0, 0.0, 0)

        n = len(samples)
        k_test = max(1, int(n * holdout_fraction))

        rng = np.random.default_rng(42)
        test_indices = rng.choice(n, size=k_test, replace=False)
        test_set = [samples[i] for i in test_indices]
        train_set = [samples[i] for i in range(n) if i not in test_indices]

        # Predict test points using train set via IDW
        residuals = []
        for tx, tz, true_rssi in test_set:
            total_w = 0.0
            sum_rssi = 0.0
            for rx, rz, train_rssi in train_set:
                d = math.hypot(tx - rx, tz - rz) + 0.1
                w = 1.0 / (d * d)
                total_w += w
                sum_rssi += w * train_rssi

            pred_rssi = sum_rssi / total_w if total_w > 0 else -95.0
            residuals.append(pred_rssi - true_rssi)

        res_arr = np.array(residuals)
        rmse = float(np.sqrt(np.mean(res_arr**2)))
        mae = float(np.mean(np.abs(res_arr)))

        return RfCrossValidationResult(
            holdout_rmse_dbm=round(rmse, 2),
            mean_absolute_error_dbm=round(mae, 2),
            test_sample_count=k_test,
        )
