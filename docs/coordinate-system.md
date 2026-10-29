# Coordinate System & Mathematical Conventions

Wallahi defines a strict Cartesian metric reference frame across camera tracking, geometry extraction, radio sensor fusion, and visualization.

---

## 1. Frame Invariants

| Attribute | Convention | Description |
| :--- | :--- | :--- |
| **Origin $(0, 0, 0)$** | Anchor Pose | Established at scan start on the detected floor plane directly beneath the initial camera pose. |
| **Up Vector** | $+Y$ | Aligned antiparallel to gravity vector determined by the device IMU. |
| **Floor Plane** | $XZ$ | $Y = 0$ corresponds to the estimated floor level. Positive $Y$ extends toward the ceiling. |
| **Handedness** | Right-handed | $+X$ points to the right, $+Y$ points up, $+Z$ points backwards/toward the viewer. |
| **Units** | Metric | All lengths in meters ($m$), angles in radians ($rad$), time in UTC ISO 8601 strings. |

---

## 2. Transformations & Conversions

### 2.1 3D AR Pose to 2D Floor Plan Space
The ARCore / ARKit pose provides a 3D position vector $\mathbf{p} = (x, y, z)$ and a rotation quaternion $\mathbf{q} = (q_x, q_y, q_z, q_w)$.

To map a 3D position to the 2D floor plan:
$$\mathbf{x}_{\text{floor}} = \begin{bmatrix} x \\ z \end{bmatrix}, \quad h = y$$
The floor plan treats $+X$ as horizontal screen right and $+Z$ as vertical screen down (or reversed depending on canvas orientation), preserving relative metric distances:
$$d_{2D}(\mathbf{x}_1, \mathbf{x}_2) = \sqrt{(x_2 - x_1)^2 + (z_2 - z_1)^2}$$

### 2.2 Surface Normals & Wall Orientation
Walls are modeled as vertical 2D line segments projected onto the $XZ$ plane with a constant height $H$:
$$W_k = (\mathbf{s}_k, \mathbf{e}_k, H_k, T_k)$$
where $\mathbf{s}_k = (x_s, z_s)$ is the start vertex, $\mathbf{e}_k = (x_e, z_e)$ is the end vertex, $H_k$ is wall height, and $T_k$ is wall thickness (default $0.15\text{ m}$).

The wall normal in 2D is:
$$\mathbf{n}_k = \frac{\begin{bmatrix} -(z_e - z_s) \\ x_e - x_s \end{bmatrix}}{\|\mathbf{e}_k - \mathbf{s}_k\|}$$

---

## 3. Pose Interpolation Across Time
When a Wi-Fi scan arrives at timestamp $t_w$, the device position is interpolated between the two closest AR poses $P_a(t_a)$ and $P_b(t_b)$ where $t_a \le t_w \le t_b$:
$$\alpha = \frac{t_w - t_a}{t_b - t_a}, \quad \alpha \in [0, 1]$$
$$\mathbf{p}(t_w) = (1 - \alpha) \mathbf{p}(t_a) + \alpha \mathbf{p}(t_b)$$
$$\mathbf{q}(t_w) = \text{Slerp}(\mathbf{q}(t_a), \mathbf{q}(t_b), \alpha)$$
If $t_b - t_a > 0.200\text{ s}$ (tracking gap), the sample is flagged with reduced confidence.
