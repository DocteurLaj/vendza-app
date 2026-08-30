import 'package:flutter/material.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/auth/presantation/pages/login_page.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_card.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_layout.dart';
import 'package:vendza/features/auth/presantation/widgets/input_widget.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.token});

  final String token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _authApiService = AuthApiService();
  bool _isLoading = false;

  bool get _hasToken => widget.token.trim().isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _resetPassword() async {
    if (!_hasToken) return;
    final password = _passwordController.text;
    final confirmation = _confirmationController.text;
    if (password.length < 8) {
      _showMessage('Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (password != confirmation) {
      _showMessage('Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authApiService.resetPassword(
        token: widget.token.trim(),
        newPassword: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour.')),
      );
      _goToLogin();
    } on ApiException catch (error) {
      if (!mounted) return;
      final status = error.statusCode;
      if (status == 400 || status == 404 || status == 410) {
        _showMessage(
          'Ce lien est invalide ou a déjà été utilisé. Demandez un nouveau lien.',
        );
      } else {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasToken) {
      return AuthLayout(
        compactHeaderHeightFactor: 0.38,
        child: AuthCard(
          title: 'Lien invalide',
          subtitle:
              'Ce lien de réinitialisation est incomplet. Demandez un nouveau lien depuis la page de connexion.',
          heightFactor: 0.42,
          children: [
            AppBouton(
              text: 'Retour à la connexion',
              onPressed: _goToLogin,
              enabled: true,
            ),
          ],
        ),
      );
    }

    return AuthLayout(
      compactHeaderHeightFactor: 0.38,
      child: AuthCard(
        title: 'Nouveau mot de passe',
        subtitle: 'Choisissez un nouveau mot de passe pour votre compte.',
        heightFactor: 0.53,
        children: [
          MyTextField(
            controller: _passwordController,
            hintText: 'Nouveau mot de passe',
            obscureText: true,
            iconPrefix: Icons.lock_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          MyTextField(
            controller: _confirmationController,
            hintText: 'Confirmer le mot de passe',
            obscureText: true,
            iconPrefix: Icons.lock_reset_outlined,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          AppBouton(
            text: _isLoading ? 'Mise à jour...' : 'Mettre à jour',
            onPressed: _isLoading ? null : _resetPassword,
            enabled: !_isLoading,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
