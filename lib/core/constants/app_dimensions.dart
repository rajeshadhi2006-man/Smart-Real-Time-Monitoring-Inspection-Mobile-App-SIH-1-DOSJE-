import 'package:flutter/material.dart';

/// Centralized spacing, padding, and layout dimensions
class AppDimensions {
  const AppDimensions._();

  // Spacing / Margins / Padding
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Border Radius
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 16.0;
  static const double radiusPill = 999.0;

  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));

  // Component Dimensions
  static const double buttonHeight = 48.0;
  static const double inputHeight = 52.0;
  static const double cardElevation = 1.0;
  static const double dialogElevation = 4.0;

  // Touch Target (Accessible enterprise guidelines)
  static const double minTouchTarget = 48.0;
}
