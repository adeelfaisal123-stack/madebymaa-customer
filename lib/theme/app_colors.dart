import 'package:flutter/material.dart';

/// Brand palette: Made by Maa purple + fresh market accents.
abstract final class AppColors {
  static const brandPurple = Color(0xFF6221B3);
  static const brandPurpleDeep = Color(0xFF3D1570);
  static const brandPurpleLight = Color(0xFF8B5CF6);
  static const amberGlow = Color(0xFFE8C468);
  static const terracotta = Color(0xFFD4622A);
  /// Primary text and chrome (legacy name — brand deep purple).
  static const deepGreen = brandPurpleDeep;
  /// Secondary accent (legacy name — brand purple).
  static const sage = brandPurple;
  static const cream = Color(0xFFFFFFFF);

  /// Ambient floating food icons — dark creamy beige.
  static const floatingIconSilver = Color(0xFF9A8668);

  /// Solid light purple for home sticky bar and view-all CTA.
  static const homeLightPurple = Color(0xFFEDE4FF);
}
