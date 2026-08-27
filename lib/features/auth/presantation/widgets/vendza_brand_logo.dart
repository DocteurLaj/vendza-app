import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';

class VendzaBrandLogo extends StatelessWidget {
  const VendzaBrandLogo({super.key, this.mode = AuthLayoutMode.compact});

  final AuthLayoutMode mode;

  static const String lightModeAsset = 'assets/icons/icon_white.png';
  static const String darkModeAsset = 'assets/icons/icon.png';

  double get _size => switch (mode) {
    AuthLayoutMode.compact => 96,
    AuthLayoutMode.medium => 112,
    AuthLayoutMode.expanded => 128,
  };

  static String assetForTheme(BuildContext context) {
    return AppColors.isDark(context) ? darkModeAsset : lightModeAsset;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetForTheme(context),
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
      ),
    );
  }
}
