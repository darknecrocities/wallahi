import 'package:flutter/material.dart';

/// Semantic, accessible color tokens for Wallahi mobile UI and RF heatmaps.
class AppColors {
  // Brand & Backgrounds
  static const Color background = Color(0xFF0F172A); // Deep slate
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF334155);
  static const Color border = Color(0xFF475569);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Status & Signals
  static const Color accent = Color(0xFF38BDF8); // Sky blue
  static const Color success = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red

  // RF Heatmap Color Ramp (-90 dBm to -35 dBm)
  static Color rssiToColor(double rssiDbm, {double opacity = 0.85}) {
    // Clamp between -90 dBm (dead zone) and -35 dBm (router adjacent)
    final normalized = ((rssiDbm - (-90.0)) / ((-35.0) - (-90.0))).clamp(0.0, 1.0);

    if (normalized < 0.25) {
      // Weak: Deep Red to Amber
      final t = normalized / 0.25;
      return Color.lerp(
        danger.withOpacity(opacity),
        warning.withOpacity(opacity),
        t,
      )!;
    } else if (normalized < 0.65) {
      // Moderate: Amber to Sky Blue
      final t = (normalized - 0.25) / 0.40;
      return Color.lerp(
        warning.withOpacity(opacity),
        accent.withOpacity(opacity),
        t,
      )!;
    } else {
      // Strong: Sky Blue to Emerald Green
      final t = (normalized - 0.65) / 0.35;
      return Color.lerp(
        accent.withOpacity(opacity),
        success.withOpacity(opacity),
        t,
      )!;
    }
  }
}
