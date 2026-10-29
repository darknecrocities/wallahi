"""Optional FastAPI processing service for heavy point-cloud & RF simulation."""

from typing import List, Tuple
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from processing.floorplan.regularizer import FloorplanRegularizer, Wall2D
from processing.evaluation.benchmark_evaluator import BenchmarkEvaluator

app = FastAPI(
    title="Wallahi Spatial RF Backend",
    version="1.0.0",
    description="Optional geometry regularization and RF cross-validation backend.",
)


class WallPayload(BaseModel):
    wall_id: str
    start_x: float
    start_z: float
    end_x: float
    end_z: float
    height_m: float = 2.8


class RegularizeRequest(BaseModel):
    walls: List[WallPayload]
    angle_tolerance_deg: float = Field(default=12.0, ge=1.0, le=45.0)
    snap_distance_m: float = Field(default=0.25, ge=0.01, le=1.0)


class RfSamplePayload(BaseModel):
    x: float
    z: float
    rssi_dbm: float


class CrossValidationRequest(BaseModel):
    samples: List[RfSamplePayload]
    holdout_fraction: float = Field(default=0.20, ge=0.1, le=0.5)


@app.get("/api/v1/health")
def health_check():
    """Health probe confirming service operational status."""
    return {"status": "healthy", "service": "wallahi-backend", "version": "1.0.0"}


@app.post("/api/v1/regularize-floorplan")
def regularize_floorplan(payload: RegularizeRequest):
    """Snaps wall segments orthogonally and resolves corner gaps."""
    if not payload.walls:
        raise HTTPException(
            status_code=400,
            detail="Wall payload cannot be empty.",
        )

    reg = FloorplanRegularizer(
        angle_tolerance_deg=payload.angle_tolerance_deg,
        snap_dist_m=payload.snap_distance_m,
    )
    walls2d = [
        Wall2D(
            wall_id=w.wall_id,
            start_x=w.start_x,
            start_z=w.start_z,
            end_x=w.end_x,
            end_z=w.end_z,
            height_m=w.height_m,
        )
        for w in payload.walls
    ]

    snapped = [reg.snap_orthogonal(w) for w in walls2d]
    closed = reg.close_loops(snapped)

    return {
        "regularized_walls": [
            {
                "wall_id": w.wall_id,
                "start_x": round(w.start_x, 4),
                "start_z": round(w.start_z, 4),
                "end_x": round(w.end_x, 4),
                "end_z": round(w.end_z, 4),
                "height_m": w.height_m,
            }
            for w in closed
        ]
    }


@app.post("/api/v1/evaluate-rf-holdout")
def evaluate_rf_holdout(payload: CrossValidationRequest):
    """Executes Leave-K-Out cross-validation on RF samples returning RMSE & MAE."""
    if len(payload.samples) < 5:
        raise HTTPException(
            status_code=400,
            detail="Minimum 5 samples required for statistical cross validation.",
        )

    samples_tuple = [(s.x, s.z, s.rssi_dbm) for s in payload.samples]
    result = BenchmarkEvaluator.evaluate_rf_cross_validation(
        samples_tuple, holdout_fraction=payload.holdout_fraction
    )

    return {
        "holdout_rmse_dbm": result.holdout_rmse_dbm,
        "mean_absolute_error_dbm": result.mean_absolute_error_dbm,
        "test_sample_count": result.test_sample_count,
    }
