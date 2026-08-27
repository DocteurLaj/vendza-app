import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

Future<bool> showCategoryChangeWarningDialog({
  required BuildContext context,
  required int productCount,
  required String categoryName,
}) async {
  final result = await showAppPopup<bool>(
    context: context,
    size: PopupSize.small,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Changer de catégorie ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              productCount == 1
                  ? 'Ce produit est déjà dans une autre catégorie. Si tu continues, il sera déplacé vers $categoryName.'
                  : '$productCount produits sont déjà dans une autre catégorie. Si tu continues, ils seront déplacés vers $categoryName.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF203640),
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            AppPopupActions(
              cancelLabel: 'Refuser',
              confirmLabel: 'Continuer',
              onCancel: () => Navigator.pop(context, false),
              onConfirm: () => Navigator.pop(context, true),
              confirmBackgroundColor: AppColors.primary,
            ),
          ],
        ),
      );
    },
  );

  return result ?? false;
}
