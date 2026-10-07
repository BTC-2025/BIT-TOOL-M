import 'package:flutter/material.dart';

class AppSpacing {
  // Common padding and margin values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Specific use cases
  static const double screenMargin = 16.0;
  static const double cardPadding = 16.0;
  static const double elementSpacing = 12.0;

  // EdgeInsets helpers
  static const EdgeInsets screenPadding = EdgeInsets.all(screenMargin);
  static const EdgeInsets defaultCardPadding = EdgeInsets.all(cardPadding);

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: screenMargin,
  );
  static const EdgeInsets screenVertical = EdgeInsets.symmetric(
    vertical: screenMargin,
  );
}
