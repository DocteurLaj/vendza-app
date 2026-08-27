import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';

class AppPopupActions extends StatelessWidget {
  const AppPopupActions({
    super.key,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.confirmBackgroundColor,
    this.confirmForegroundColor,
    this.cancelBorderColor,
    this.cancelForegroundColor,
    this.buttonPadding = const EdgeInsets.symmetric(vertical: 12),
    this.borderRadius = 10,
    this.spacing = 12,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final Color? confirmBackgroundColor;
  final Color? confirmForegroundColor;
  final Color? cancelBorderColor;
  final Color? cancelForegroundColor;
  final EdgeInsetsGeometry buttonPadding;
  final double borderRadius;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final confirmForeground =
        confirmForegroundColor ??
        (AppColors.isDark(context) ? AppColors.darkBackground : Colors.white);
    final useRow = AppBreakpoints.usePopupActionsRow(
      MediaQuery.sizeOf(context).width,
    );

    final cancelButton = OutlinedButton(
      onPressed: onCancel,
      style: OutlinedButton.styleFrom(
        foregroundColor: cancelForegroundColor ?? accent,
        side: BorderSide(
          color: cancelBorderColor ?? accent.withValues(alpha: 0.55),
        ),
        padding: buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Text(cancelLabel),
    );

    final confirmButton = ElevatedButton(
      onPressed: onConfirm,
      style: ElevatedButton.styleFrom(
        backgroundColor: confirmBackgroundColor ?? accent,
        foregroundColor: confirmForeground,
        elevation: 0,
        padding: buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Text(confirmLabel),
    );

    if (useRow) {
      return Row(
        children: [
          Expanded(child: cancelButton),
          SizedBox(width: spacing),
          Expanded(child: confirmButton),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        confirmButton,
        SizedBox(height: spacing),
        cancelButton,
      ],
    );
  }
}
