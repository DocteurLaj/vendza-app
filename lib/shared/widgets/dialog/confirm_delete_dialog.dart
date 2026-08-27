import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

Future<bool> showConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final result = await showAppPopup<bool>(
    context: context,
    size: PopupSize.small,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.shade700,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF203640),
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            AppPopupActions(
              cancelLabel: 'Annuler',
              confirmLabel: 'Supprimer',
              onCancel: () => Navigator.pop(context, false),
              onConfirm: () => Navigator.pop(context, true),
              confirmBackgroundColor: Colors.red.shade700,
              buttonPadding: const EdgeInsets.symmetric(vertical: 13),
              borderRadius: 12,
            ),
          ],
        ),
      );
    },
  );

  return result ?? false;
}

PreferredSizeWidget buildSelectionAppBar({
  required BuildContext context,
  required int selectedCount,
  required VoidCallback onCancel,
  required VoidCallback onSelectAll,
  required VoidCallback onDelete,
}) {
  return AppBar(
    leading: IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
    title: Text('$selectedCount sélectionné(s)'),
    actions: [
      IconButton(
        tooltip: 'Tout sélectionner',
        icon: const Icon(Icons.select_all),
        onPressed: onSelectAll,
      ),
      IconButton(
        tooltip: 'Supprimer',
        icon: const Icon(Icons.delete_outline),
        onPressed: selectedCount == 0 ? null : onDelete,
      ),
    ],
    backgroundColor: AppColors.accent(context),
    foregroundColor: AppColors.isDark(context)
        ? AppColors.darkBackground
        : Colors.white,
  );
}
