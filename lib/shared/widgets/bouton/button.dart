import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class AppBouton extends StatelessWidget {
  const AppBouton({
    super.key,
    required this.text,
    this.textColor,
    this.backgroundColor,
    required this.onPressed,
    required this.enabled,
    this.isLoading = false,
    this.loadingText,
  });

  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final Color? backgroundColor;
  final bool enabled;
  final bool isLoading;
  final String? loadingText;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !isLoading && onPressed != null;
    final label = isLoading ? (loadingText ?? 'Chargement...') : text;
    final foreground =
        textColor ??
        (AppColors.isDark(context) ? AppColors.darkBackground : Colors.white);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.accent(context),
        disabledBackgroundColor: AppColors.muted(
          context,
        ).withValues(alpha: 0.28),
        disabledForegroundColor: AppColors.textSecondary(context),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: canTap ? onPressed : null,
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : Text(label, style: TextStyle(color: foreground)),
    );
  }
}
