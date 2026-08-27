import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class ListButton extends StatelessWidget {
  const ListButton({
    super.key,
    required this.text,
    required this.iconData,
    required this.onPressed,
    this.leading,
    this.onLongPress,
    this.isSelected = false,
  });

  final String text;
  final IconData iconData;
  final VoidCallback onPressed;
  final Widget? leading;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppInteractive(
          onTap: onPressed,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(11),
          enableHoverElevation: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent(context).withValues(alpha: 0.12)
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(11),
              border: isSelected
                  ? Border.all(color: AppColors.accent(context), width: 1.4)
                  : Border.all(color: AppColors.border(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  leading ??
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent(
                            context,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          iconData,
                          color: AppColors.iconAccent(context),
                        ),
                      ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.cardTitle(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.accent(context),
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
