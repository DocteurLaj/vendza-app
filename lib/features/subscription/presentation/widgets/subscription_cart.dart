import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.sub,
    required this.isSelected,
    required this.onTap,
  });

  final SubscriptionModel sub;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      enableHoverElevation: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent(context).withValues(alpha: 0.12)
              : AppColors.card(context),
          border: Border.all(
            color: isSelected
                ? AppColors.accent(context)
                : AppColors.border(context),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                sub.title,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'FC ${sub.price}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub.subtitle,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.isDark(context)
                      ? const Color(0xFFFF8661)
                      : const Color.fromARGB(255, 255, 134, 97),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
