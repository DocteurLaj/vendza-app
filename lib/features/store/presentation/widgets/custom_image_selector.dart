import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class CustomImageSelector extends StatelessWidget {
  const CustomImageSelector({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.icon,
    required this.onTap,
    this.height = 132,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final IconData icon;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      enableHoverElevation: true,
      child: Container(
        width: double.infinity,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.softSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Positioned.fill(
                child: SmartImage(path: imageUrl, fit: BoxFit.cover),
              ),
            Container(
              decoration: BoxDecoration(
                color: imageUrl.isEmpty
                    ? AppColors.accent(context).withValues(alpha: 0.055)
                    : Colors.black.withValues(alpha: 0.26),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 42,
                    decoration: BoxDecoration(
                      color: imageUrl.isEmpty
                          ? AppColors.card(context)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: imageUrl.isEmpty
                            ? AppColors.border(context)
                            : Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Icon(icon, color: AppColors.iconAccent(context)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cardTitle(context).copyWith(
                      color: imageUrl.isEmpty
                          ? AppColors.cardTitle(context)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle(context).copyWith(
                      color: imageUrl.isEmpty
                          ? AppColors.subtitleText(context)
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
