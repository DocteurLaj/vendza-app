import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class AppSearchBarStyle {
  static const double idleHeight = 45;
  static const double activeHeight = 48;
  static const double idleBorderRadius = 30;
  static const double activeBorderRadius = 14;
  static const double fontSize = 14;
  static const Duration animationDuration = Duration(milliseconds: 240);

  static double height({required bool isActive}) =>
      isActive ? activeHeight : idleHeight;

  static double borderRadius({required bool isActive}) =>
      isActive ? activeBorderRadius : idleBorderRadius;

  static Color backgroundColor(BuildContext context, {required bool isActive}) {
    return isActive
        ? AppColors.card(context)
        : AppColors.searchSurface(context);
  }

  static Color borderColor(BuildContext context, {required bool isActive}) {
    return isActive
        ? AppColors.accent(context).withValues(alpha: 0.30)
        : AppColors.border(context);
  }

  static List<BoxShadow>? boxShadow(
    BuildContext context, {
    required bool isActive,
  }) {
    if (!isActive) return null;

    return [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: AppColors.isDark(context) ? 0.18 : 0.04,
        ),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static FontWeight fontWeight({required bool isActive}) =>
      isActive ? FontWeight.w600 : FontWeight.w500;
}
