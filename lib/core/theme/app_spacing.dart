import 'package:flutter/material.dart';

/// Centralized Grid Spacing for NUBIKO
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Insets
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 20.0,
  );
  static const EdgeInsets mobilePagePadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);
}
