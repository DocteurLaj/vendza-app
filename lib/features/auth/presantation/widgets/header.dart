import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/strings.dart';
import 'package:vendza/features/auth/presantation/widgets/vendza_brand_logo.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key, this.mode = AuthLayoutMode.compact});

  final AuthLayoutMode mode;

  double get _appNameSize => switch (mode) {
    AuthLayoutMode.compact => 28,
    AuthLayoutMode.medium => 32,
    AuthLayoutMode.expanded => 36,
  };

  @override
  Widget build(BuildContext context) {
    final subtitleColor = mode == AuthLayoutMode.expanded
        ? AppColors.textSecondary(context)
        : AppColors.textgray;
    final welcomeColor = mode == AuthLayoutMode.expanded
        ? AppColors.textSecondary(context)
        : AppColors.textgray;
    final appNameColor = mode == AuthLayoutMode.expanded
        ? AppColors.textPrimary(context)
        : AppColors.textwhite;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VendzaBrandLogo(mode: mode),
        SizedBox(height: mode == AuthLayoutMode.expanded ? 24 : 20),
        Text(
          'Bienvenue dans',
          style: TextStyle(color: welcomeColor, fontSize: 16),
        ),
        const SizedBox(height: 5),
        Text(
          AppStrings.appName,
          style: TextStyle(
            color: appNameColor,
            fontSize: _appNameSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Votre Application mobile',
          style: TextStyle(color: subtitleColor),
        ),
      ],
    );
  }
}
