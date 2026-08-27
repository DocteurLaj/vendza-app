import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class MenuItemWidget extends StatelessWidget {
  const MenuItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      enableHoverElevation: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.iconAccent(context)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.cardTitle(
                  context,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.muted(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
