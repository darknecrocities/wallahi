# RF Propagation & Heatmap Interpolation Models

This document specifies the mathematical formulations used in Wallahi for radio propagation modeling, spatial interpolation, uncertainty quantification, and RTT multilateration.

---

## 1. Log-Distance Path Loss Model

Indoor RF attenuation over distance $d$ is characterized by the Log-Distance Path Loss model with shadow fading:
$$PL(d) = PL(d_0) + 10 \cdot n \cdot \log_{10}\left(\frac{d}{d_0}\right) + X_\sigma$$
where:
- $d_0$ is the reference distance (typically $1.0\text{ m}$).
- $PL(d_0)$ is the free-space path loss at distance $d_0$:
  $$PL(d_0) = 20 \log_{10}(f_{\text{MHz}}) - 27.55$$
- $n$ is the path loss exponent ($n \approx 1.6 - 2.0$ for open corridors, $n \approx 2.5 - 3.5$ for residential rooms with drywall, $n \approx 4.0 - 6.0$ for concrete multi-wall environments).
- $X_\sigma \sim \mathcal{N}(0, \sigma^2)$ represents zero-mean Gaussian shadow fading due to multipath obstacles ($4\text{ dB} \le \sigma \le 12\text{ dB}$).

Received Signal Strength (RSSI in dBm) from transmitter with power $P_{tx}$ and antenna gain $G$:
$$R(d) = P_{tx} + G - PL(d)$$

---

## 2. Spatial Heatmap Interpolation

### 2.1 Inverse Distance Weighting (IDW)
Given $N$ registered spatial Wi-Fi measurements $(p_i, R_i)_{i=1}^N$:
$$\hat{R}(\mathbf{x}) = \frac{\sum_{i=1}^N w_i(\mathbf{x}) R_i}{\sum_{i=1}^N w_i(\mathbf{x})}$$
$$w_i(\mathbf{x}) = \frac{1}{(d(\mathbf{x}, \mathbf{p}_i) + \epsilon)^p}$$
- Default power exponent: $p = 2.0$ (smooth decay).
- Smoothing parameter: $\epsilon = 0.1\text{ m}$ to prevent divide-by-zero singularities when $\mathbf{x} \to \mathbf{p}_i$.
- Spatial cutoff radius: $R_{\text{cutoff}} = 4.0\text{ m}$.

### 2.2 Spatial Uncertainty Field
Uncertainty $U(\mathbf{x}) \in [0, 1]$ increases with distance from the nearest sample:
$$U(\mathbf{x}) = 1.0 - \exp\left(-\frac{\min_i d(\mathbf{x}, \mathbf{p}_i)^2}{2 \sigma_{\text{spatial}}^2}\right)$$
Regions with $U(\mathbf{x}) \ge 0.65$ are rendered with dashed/hatched overlays and prompted for rescan.

---

## 3. Wi-Fi RTT Multilateration

When 802.11mc Fine Timing Measurement distance estimates $d_j$ are available from $M \ge 3$ access points at known or estimated positions $\mathbf{a}_j = (x_j, z_j)$:
$$\min_{\mathbf{p}} \sum_{j=1}^M \frac{1}{\sigma_j^2} \left( \|\mathbf{p} - \mathbf{a}_j\| - d_j \right)^2$$
Solved via Gauss-Newton or Levenberg-Marquardt non-linear least squares optimization.
