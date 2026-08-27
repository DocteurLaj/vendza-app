import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class AuthSwitchAction extends StatelessWidget {
  const AuthSwitchAction({
    super.key,
    required this.label,
    required this.actionText,
    required this.onTap,
  });

  final String label;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        AppInteractive(
          onTap: onTap,
          enableHoverLift: false,
          borderRadius: BorderRadius.circular(4),
          child: Text(
            actionText,
            style: TextStyle(
              color: AppColors.accent(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
