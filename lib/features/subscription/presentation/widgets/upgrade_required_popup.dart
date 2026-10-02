import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/subscription/presentation/pages/subscription_page.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

bool isPlanLimitError(Object error) {
  return error is ApiException && error.isPlanLimitReached;
}

Future<bool> showUpgradeRequiredPopupFromError({
  required BuildContext context,
  required Object error,
}) async {
  if (error is! ApiException || !error.isPlanLimitReached) return false;
  await showUpgradeRequiredPopup(context: context, error: error);
  return true;
}

Future<void> showUpgradeRequiredPopup({
  required BuildContext context,
  required ApiException error,
}) {
  final detail = error.planLimitDetail ?? const <String, dynamic>{};
  final currentPlan = detail['current_plan']?.toString();
  final requiredPlan = detail['required_plan']?.toString();
  final message = detail['message']?.toString() ?? error.message;

  return showAppPopup<void>(
    context: context,
    size: PopupSize.medium,
    builder: (dialogContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fonctionnalité réservée',
              style: AppTextStyles.pageTitle(dialogContext),
            ),
            const SizedBox(height: 10),
            Text(message, style: AppTextStyles.body(dialogContext)),
            if (currentPlan != null || requiredPlan != null) ...[
              const SizedBox(height: 10),
              Text(
                [
                  if (currentPlan != null) 'Offre actuelle : $currentPlan',
                  if (requiredPlan != null) 'Offre conseillée : $requiredPlan',
                ].join('\n'),
                style: AppTextStyles.body(dialogContext),
              ),
            ],
            const SizedBox(height: 18),
            AppPopupActions(
              cancelLabel: 'Plus tard',
              confirmLabel: 'Voir les offres',
              onCancel: () => Navigator.pop(dialogContext),
              onConfirm: () {
                Navigator.pop(dialogContext);
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
