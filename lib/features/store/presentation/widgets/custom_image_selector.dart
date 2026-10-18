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
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isCompact = height < 120;

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isCompact ? 34 : 44,
                      height: isCompact ? 34 : 42,
                      decoration: BoxDecoration(
                        color: imageUrl.isEmpty
                            ? AppColors.card(context)
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(
                          isCompact ? 10 : 12,
                        ),
                        border: Border.all(
                          color: imageUrl.isEmpty
                              ? AppColors.border(context)
                              : Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: isCompact ? 18 : 24,
                        color: AppColors.iconAccent(context),
                      ),
                    ),
                    SizedBox(height: isCompact ? 4 : 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle(context).copyWith(
                        fontSize: isCompact ? 11 : null,
                        color: imageUrl.isEmpty
                            ? AppColors.cardTitle(context)
                            : Colors.white,
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle(context).copyWith(
                          color: imageUrl.isEmpty
                              ? AppColors.subtitleText(context)
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isCompact && imageUrl.isNotEmpty)
              Positioned(
                right: 6,
                top: 6,
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
