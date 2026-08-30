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

Future<void> showForgotPasswordDialog(BuildContext context) async {
  final sent = await showAppPopup<bool>(
    context: context,
    size: PopupSize.small,
    builder: (context) => const _ForgotPasswordDialog(),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Si un compte correspond, les instructions ont \u00e9t\u00e9 envoy\u00e9es.',
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _authApiService = AuthApiService();
  var _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _error = 'Veuillez entrer une adresse email valide');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authApiService.requestPasswordReset(email);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
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
              controller: _emailController,
              hintText: 'Adresse email',
              obscureText: false,
              iconPrefix: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onDarkBackground: false,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 18),
            AppPopupActions(
              cancelLabel: 'Annuler',
              confirmLabel: _isLoading ? 'Envoi...' : 'Envoyer',
              spacing: 10,
              borderRadius: 12,
              onCancel: _isLoading ? () {} : () => Navigator.pop(context, false),
              onConfirm: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
