import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 18,
        vertical: compact ? 0 : 10,
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 20,
        compact ? 14 : 22,
        compact ? 14 : 20,
        compact ? 14 : 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(compact ? 13 : 16),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.16 : 0.025,
            ),
            blurRadius: compact ? 12 : 18,
            offset: Offset(0, compact ? 4 : 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 44 : 54,
            height: compact ? 44 : 54,
            decoration: BoxDecoration(
              color: AppColors.softSurface(context),
              borderRadius: BorderRadius.circular(compact ? 12 : 15),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Icon(
              icon,
              color: AppColors.accent(context),
              size: compact ? 23 : 28,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: compact ? 12 : 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (action != null) ...[SizedBox(height: compact ? 12 : 16), action!],
        ],
      ),
    );
  }
}
