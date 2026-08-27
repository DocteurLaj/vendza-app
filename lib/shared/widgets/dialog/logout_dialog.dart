import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/presantation/pages/login_page.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

Future<void> showLogoutDialog(BuildContext context) {
  return showAppPopup<void>(
    context: context,
    size: PopupSize.small,
    builder: (dialogContext) {
      return Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.logout, color: Color(0xFFD35454)),
              ),
              const SizedBox(height: 14),
              Text('Déconnexion', style: AppTextStyles.pageTitle(context)),
              const SizedBox(height: 8),
              Text(
                'Voulez-vous vraiment vous déconnecter de votre compte ?',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle(
                  context,
                ).copyWith(fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 18),
              AppPopupActions(
                cancelLabel: 'Annuler',
                confirmLabel: 'Oui',
                spacing: 10,
                borderRadius: 12,
                onCancel: () => Navigator.pop(dialogContext),
                onConfirm: () async {
                  Navigator.pop(dialogContext);
                  try {
                    await authSessionService.logout();
                  } finally {
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
                confirmBackgroundColor: const Color(0xFFD35454),
              ),
            ],
          ),
        ),
      );
    },
  );
}
