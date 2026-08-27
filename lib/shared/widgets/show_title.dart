import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/sizes.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class ShowTitle extends StatelessWidget {
  const ShowTitle({
    super.key,
    required this.text,
    this.showAction = true,
    this.actionLabel = 'Voir tout',
    this.onActionTap,
  });

  final String text;
  final bool showAction;
  final String actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      maxWidth: AppBreakpoints.contentMaxWidth,
      padding: const EdgeInsetsGeometry.symmetric(horizontal: AppSizes.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: AlignmentGeometry.centerLeft,
              child: Text(text, style: AppTextStyles.sectionTitle(context)),
            ),
          ),
          if (showAction)
            AppInteractive(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(8),
              enableHoverLift: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(actionLabel, style: AppTextStyles.action(context)),
              ),
            ),
        ],
      ),
    );
  }
}
