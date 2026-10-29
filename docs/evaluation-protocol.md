# Evaluation Protocol & Accuracy Benchmarking

This protocol establishes measurable verification criteria for Wallahi's computer vision and Wi-Fi sensing subsystems.

---

## 1. Geometric Accuracy Evaluation

### 1.1 Metrics
1. **Wall Dimension Error (WDE)**: Absolute difference between AR-estimated wall length $L_{\text{est}}$ and ground-truth laser distance $L_{\text{gt}}$:
   $$\text{WDE} = |L_{\text{est}} - L_{\text{gt}}|$$
   - Target benchmark: $\text{Mean WDE} \le 0.08\text{ m}$ ($8\text{ cm}$) in standard residential rooms.
2. **Perimeter Loop Closure Error (LCE)**: Distance between start point $\mathbf{s}_0$ and end point $\mathbf{e}_N$ of a closed loop traversal:
   $$\text{LCE} = \|\mathbf{e}_N - \mathbf{s}_0\|$$
   - Target benchmark: $\text{LCE} \le 0.15\text{ m}$ for rooms up to $50\text{ m}^2$.
3. **Corner Orthogonality Deviation ($\Delta \theta$)**: Angle deviation from $90^\circ$ for rectangular rooms:
   $$\Delta \theta = |\theta_{\text{corner}} - 90^\circ|$$
   - Target benchmark: Snapped model within $\pm 1.5^\circ$.

---

## 2. Wi-Fi RF Sensing Evaluation

### 2.1 Repeatability & Variance
- Multiple stationary scans at fixed reference markers:
  $$\sigma_{\text{RSSI}}^2 = \frac{1}{M-1} \sum_{j=1}^M (R_j - \bar{R})^2$$
  - Target: Median filtering across 5 consecutive samples reduces variance by $\ge 60\%$ compared to raw instantaneous RSSI.

### 2.2 Heatmap Prediction Error (Cross-Validation)
- **Leave-K-Out Cross Validation**: Withhold 20% of spatial samples as test set $S_{\text{test}}$. Interpolate surface $\hat{R}(\mathbf{x})$ using remaining 80% $S_{\text{train}}$.
- Compute Root Mean Squared Error (RMSE):
  $$\text{RMSE}_{\text{RF}} = \sqrt{\frac{1}{|S_{\text{test}}|} \sum_{i \in S_{\text{test}}} (\hat{R}(\mathbf{p}_i) - R_i)^2}$$
  - Target: $\text{RMSE} \le 4.5\text{ dBm}$ in Line-of-Sight (LoS) environments; $\le 7.0\text{ dBm}$ in Non-Line-of-Sight (NLoS) multipath environments.

---

## 3. Sensor Fusion & Association Quality

- **Trajectory Drift under Dynamic Motion**: Evaluation of AR pose stability under fast rotation ($> 2.0\text{ rad/s}$).
- **Spatial Hole Detection**: Recall rate of unvisited room quadrants ($> 1.5\text{ m}$ from any sample) identified for rescan guidance.
