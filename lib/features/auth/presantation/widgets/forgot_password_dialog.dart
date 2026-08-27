import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/auth/presantation/widgets/input_widget.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

Future<void> showForgotPasswordDialog(BuildContext context) {
  final emailController = TextEditingController();
  final authApiService = AuthApiService();
  var isLoading = false;

  return showAppPopup<void>(
    context: context,
    size: PopupSize.small,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Mot de passe oubli\u00e9',
                  style: AppTextStyles.pageTitle(context),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez votre adresse email pour recevoir un lien de r\u00e9initialisation.',
                  style: AppTextStyles.subtitle(
                    context,
                  ).copyWith(fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 16),
                MyTextField(
                  controller: emailController,
                  hintText: 'Adresse email',
                  obscureText: false,
                  iconPrefix: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onDarkBackground: false,
                ),
                const SizedBox(height: 18),
                AppPopupActions(
                  cancelLabel: 'Annuler',
                  confirmLabel: isLoading ? 'Envoi...' : 'Envoyer',
                  spacing: 10,
                  borderRadius: 12,
                  onCancel: isLoading
                      ? () {}
                      : () => Navigator.pop(dialogContext),
                  onConfirm: () async {
                    if (isLoading) return;
                    final email = emailController.text.trim();
                    if (!isValidEmail(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez entrer une adresse email valide',
                          ),
                        ),
                      );
                      return;
                    }
                    setDialogState(() => isLoading = true);
                    try {
                      await authApiService.requestPasswordReset(email);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Si un compte correspond, les instructions ont \u00e9t\u00e9 envoy\u00e9es.',
                          ),
                        ),
                      );
                    } on ApiException catch (error) {
                      if (!dialogContext.mounted) return;
                      setDialogState(() => isLoading = false);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.message)));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(emailController.dispose);
}
