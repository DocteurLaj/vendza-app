import 'package:flutter/material.dart';
import 'package:vendza/core/config/google_auth_config.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/strings.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/presantation/pages/register_page.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_card.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_layout.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_switch_action.dart';
import 'package:vendza/features/auth/presantation/widgets/forgot_password_dialog.dart';
import 'package:vendza/features/auth/presantation/widgets/google_sign_in_button.dart';
import 'package:vendza/features/auth/presantation/widgets/input_widget.dart';
import 'package:vendza/navigation/main_page.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading || _isGoogleLoading) return;
    if (!NetworkStatus.ensureOnline(context)) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse email valide'),
        ),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe est requis')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await authSessionService.loginWithEmail(email: email, password: password);
      if (!mounted) return;
      _openMainPage();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openMainPage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainPage()),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      compactHeaderHeightFactor: 0.42,
      child: AuthCard(
        title: AppStrings.login,
        heightFactor: 0.62,
        children: [
          MyTextField(
            controller: _emailController,
            hintText: 'Adresse email',
            obscureText: false,
            iconPrefix: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          MyTextField(
            controller: _passwordController,
            hintText: 'Mot de passe',
            obscureText: true,
            iconPrefix: Icons.lock_outline,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => showForgotPasswordDialog(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent(context),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppBouton(
            text: AppStrings.login,
            loadingText: 'Connexion...',
            onPressed: _login,
            enabled: !_isLoading && !_isGoogleLoading,
            isLoading: _isLoading,
          ),
          if (GoogleAuthConfig.isConfigured) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.border(context))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: TextStyle(color: AppColors.textSecondary(context)),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.border(context))),
              ],
            ),
            const SizedBox(height: 18),
            GoogleSignInButton(
              enabled: !_isLoading,
              onLoadingChanged: (isLoading) {
                if (mounted) setState(() => _isGoogleLoading = isLoading);
              },
              onAuthenticated: _openMainPage,
            ),
          ],
          const SizedBox(height: 18),
          AuthSwitchAction(
            label: 'Vous n\'avez pas encore de compte ?',
            actionText: 'S\'inscrire',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
