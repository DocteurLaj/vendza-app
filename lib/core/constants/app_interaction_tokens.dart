import 'package:flutter/material.dart';

class AppInteractionTokens {
  const AppInteractionTokens._();

  static const double hoverScale = 1.02;
  static const double pressedScale = 0.97;
  static const Duration duration = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOutCubic;
  static const double hoverShadowBlur = 10;
  static const Offset hoverShadowOffset = Offset(0, 3);
  static const double hoverShadowAlphaLight = 0.05;
  static const double hoverShadowAlphaDark = 0.12;
  static const double splashAlpha = 0.06;
  static const double highlightAlpha = 0.03;
  static const double pressedOverlayAlpha = 0.08;
  static const double hoverOverlayAlpha = 0.04;
}
