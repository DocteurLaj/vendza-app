import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.visual,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? visual;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppColors.isDark(context) ? 0.16 : 0.04,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: visual ?? Icon(icon, color: AppColors.iconAccent(context)),
          ),
          const SizedBox(height: 5),
          Text(label, style: AppTextStyles.label(context)),
        ],
      ),
    );
  }
}
