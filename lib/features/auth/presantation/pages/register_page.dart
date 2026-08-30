import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vendza/core/config/google_auth_config.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/site_links.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/presantation/pages/login_page.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_card.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_layout.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_switch_action.dart';
import 'package:vendza/features/auth/presantation/widgets/google_sign_in_button.dart';
import 'package:vendza/features/auth/presantation/widgets/input_widget.dart';
import 'package:vendza/navigation/main_page.dart';
import 'package:vendza/shared/utils/phone_number.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/input/phone_number_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isChecked = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneFieldKey = GlobalKey<PhoneNumberFieldState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isLoading || _isGoogleLoading) return;
    if (!NetworkStatus.ensureOnline(context)) return;
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone =
        _phoneFieldKey.currentState?.value ?? parsePhoneNumber('');
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (fullName.isEmpty) {
      _showError('Le nom complet est requis');
      return;
    }
    if (!isValidEmail(email)) {
      _showError('Veuillez entrer une adresse email valide');
      return;
    }
    if (!phone.isValid) {
      _showError(
        phone.national.isEmpty
            ? 'Le numéro de téléphone est requis'
            : 'Le numéro de téléphone est incomplet',
      );
      return;
    }
    if (password.length < 8) {
      _showError('Le mot de passe doit contenir au moins 8 caract\u00e8res');
      return;
    }
    if (password != confirm) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await authSessionService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone.e164,
      );
      if (!mounted) return;
      _openMainPage();
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openMainPage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      compactHeaderHeightFactor: 0.28,
      compactHeaderTopPadding: 18,
      child: AuthCard(
        title: 'Inscription',
        subtitle:
            'Cr\u00e9ez votre compte pour acheter, vendre et suivre vos boutiques.',
        heightFactor: 0.82,
        children: [
          MyTextField(
            controller: _nameController,
            hintText: 'Nom complet',
            obscureText: false,
            iconPrefix: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _fieldGap(context)),
          MyTextField(
            controller: _emailController,
            hintText: 'Adresse email',
            obscureText: false,
            iconPrefix: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _fieldGap(context)),
          PhoneNumberField(
            key: _phoneFieldKey,
            label: 'Numéro de téléphone',
            enabled: !_isLoading && !_isGoogleLoading,
          ),
          SizedBox(height: _fieldGap(context)),
          MyTextField(
            controller: _passwordController,
            hintText: 'Mot de passe',
            obscureText: true,
            iconPrefix: Icons.lock_outline,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _fieldGap(context)),
          MyTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirmer le mot de passe',
            obscureText: true,
            iconPrefix: Icons.lock_outline,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: _fieldGap(context)),
          _TermsCheckbox(
            value: isChecked,
            onChanged: (value) {
              setState(() {
                isChecked = value ?? false;
              });
            },
          ),
          const SizedBox(height: 22),
          AppBouton(
            text: 'S\u2019inscrire',
            loadingText: 'Inscription...',
            backgroundColor: isChecked
                ? AppColors.accent(context)
                : const Color(0xFFB8C2C4),
            onPressed: _register,
            enabled: isChecked && !_isLoading && !_isGoogleLoading,
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
              enabled: isChecked && !_isLoading,
              onLoadingChanged: (isLoading) {
                if (mounted) setState(() => _isGoogleLoading = isLoading);
              },
              onAuthenticated: _openMainPage,
            ),
          ],
          const SizedBox(height: 18),
          AuthSwitchAction(
            label: 'Vous avez d\u00e9j\u00e0 un compte ?',
            actionText: 'Connexion',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  double _fieldGap(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact =
        AppBreakpoints.authLayoutMode(width) == AuthLayoutMode.compact;
    final isShortScreen = MediaQuery.sizeOf(context).height < 700;

    if (isCompact && isShortScreen) return 10;
    if (isCompact) return 12;
    return 14;
  }
}

Future<void> _openLegalPage(String url) async {
  await SiteLinks.open(url);
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.softSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.accent(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: AppColors.accent(context),
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    const TextSpan(text: 'J\u2019accepte les '),
                    TextSpan(
                      text: 'conditions d\u2019utilisation',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _openLegalPage(SiteLinks.terms),
                    ),
                    const TextSpan(text: ' et la '),
                    TextSpan(
                      text: 'politique de confidentialité',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _openLegalPage(SiteLinks.privacy),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
