import 'package:flutter/material.dart';

enum AuthLayoutMode { compact, medium, expanded }

enum PopupSize { small, medium, large }

class AppBreakpoints {
  static const double authCompact = 600;
  static const double popupCompact = 600;
  static const double navigationRail = 840;
  static const double contentMaxWidth = 920;

  static bool useNavigationRail(double width) => width >= navigationRail;

  static AuthLayoutMode authLayoutMode(double width) {
    if (width >= navigationRail) return AuthLayoutMode.expanded;
    if (width >= authCompact) return AuthLayoutMode.medium;
    return AuthLayoutMode.compact;
  }

  static double popupMaxWidth(double screenWidth, PopupSize size) {
    final maxForSize = switch (size) {
      PopupSize.small => 400.0,
      PopupSize.medium => 480.0,
      PopupSize.large => 640.0,
    };

    if (screenWidth < popupCompact) {
      return screenWidth - 32;
    }

    return maxForSize;
  }

  static EdgeInsets popupInsetPadding(double screenWidth) {
    if (screenWidth >= navigationRail) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (screenWidth >= popupCompact) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 24);
  }

  static double popupMaxHeight(double screenHeight, {bool scrollable = false}) {
    final dynamicHeight = screenHeight * 0.85;
    if (!scrollable) return dynamicHeight;
    return dynamicHeight.clamp(0, 590).toDouble();
  }

  static int imageGridCrossAxisCount(double screenWidth) {
    if (screenWidth >= navigationRail) return 5;
    if (screenWidth >= popupCompact) return 4;
    return 3;
  }

  static bool usePopupActionsRow(double availableWidth) =>
      availableWidth >= 400;
}
