# Learned Conventions: Wallahi Spatial Mapping

## Platform & Engineering Invariants
1. **Physical Line Limit**: Strict 500-line ceiling on all source files. All domain modules kept $\le 250$ lines.
2. **Git Commit Budget**: Strict 1,000-line diff budget per commit. Multi-line Conventional Commit structure (Title under 72 chars, Context/Why, Key Changes/What, Verification/Impact).
3. **Sensor Responsibility Separation**:
   - Computer vision handles visual tracking and metric geometry.
   - Wi-Fi radio sensing handles signal strength and RTT range constraints.
   - Sensor fusion computes spatio-temporal registration and distance-penalized spatial uncertainty.
4. **Offline-First Resilience**: All core mapping, floor plan rendering, and heatmap interpolation execute completely offline on-device with zero required backend dependencies.
5. **Calibrated Confidence**: Always report uncertainty alongside measurements instead of arbitrary heuristics.
