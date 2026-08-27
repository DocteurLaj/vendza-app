import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class TextIconButton extends StatelessWidget {
  const TextIconButton({
    super.key,
    required this.text,
    required this.iconData,
    required this.onPressed,
    this.visual,
  });

  final String text;
  final IconData iconData;
  final VoidCallback onPressed;
  final Widget? visual;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppInteractive(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        enableHoverElevation: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.searchSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      visual ??
                      Icon(iconData, color: AppColors.iconAccent(context)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cardTitle(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
