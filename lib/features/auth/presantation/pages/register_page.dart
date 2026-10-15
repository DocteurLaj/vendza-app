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
import 'package:vendza/features/auth/presantation/pages/email_verification_page.dart';
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
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;
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
    final phone = _phoneFieldKey.currentState?.value ?? parsePhoneNumber('');
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    final nameError = fullName.isEmpty ? 'Le nom complet est requis' : null;
    final emailError = !isValidEmail(email)
        ? 'Veuillez entrer une adresse email valide'
        : null;
    final phoneError = !phone.isValid
        ? (phone.national.isEmpty
              ? 'Le numéro de téléphone est requis'
              : 'Le numéro de téléphone est incomplet')
        : null;
    final passwordError = password.length < 8
        ? 'Le mot de passe doit contenir au moins 8 caractères'
        : null;
    final confirmError = password != confirm
        ? 'Les mots de passe ne correspondent pas'
        : null;
    final termsError = !isChecked
        ? 'Veuillez accepter les conditions pour continuer'
        : null;
    if (nameError != null ||
        emailError != null ||
        phoneError != null ||
        passwordError != null ||
        confirmError != null ||
        termsError != null) {
      setState(() {
        _nameError = nameError;
        _emailError = emailError;
        _phoneError = phoneError;
        _passwordError = passwordError;
        _confirmPasswordError = confirmError;
        _termsError = termsError;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final requiresVerification = await authSessionService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone.e164,
      );
      if (!mounted) return;
      if (requiresVerification) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(email: email),
          ),
        );
        return;
      }
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
            errorText: _nameError,
            onChanged: (_) => setState(() => _nameError = null),
            iconPrefix: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _fieldGap(context)),
          MyTextField(
            controller: _emailController,
            hintText: 'Adresse email',
            obscureText: false,
            errorText: _emailError,
            onChanged: (_) => setState(() => _emailError = null),
            iconPrefix: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _fieldGap(context)),
          PhoneNumberField(
            key: _phoneFieldKey,
            label: 'Numéro de téléphone',
            enabled: !_isLoading && !_isGoogleLoading,
            errorText: _phoneError,
            onChanged: (_) => setState(() => _phoneError = null),
          ),
          SizedBox(height: _fieldGap(context)),
          MyTextField(
            controller: _passwordController,
            hintText: 'Mot de passe',
            obscureText: true,
            errorText: _passwordError,
            onChanged: (_) => setState(() => _passwordError = null),
            iconPrefix: Icons.lock_outline,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: _fieldGap(context)),
          MyTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirmer le mot de passe',
            obscureText: true,
            errorText: _confirmPasswordError,
            onChanged: (_) => setState(() => _confirmPasswordError = null),
            iconPrefix: Icons.lock_outline,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: _fieldGap(context)),
          _TermsCheckbox(
            value: isChecked,
            onChanged: (value) {
              setState(() {
                isChecked = value ?? false;
                _termsError = null;
              });
            },
            errorText: _termsError,
          ),
          const SizedBox(height: 22),
          AppBouton(
            text: 'S\u2019inscrire',
            loadingText: 'Inscription...',
            backgroundColor: isChecked
                ? AppColors.accent(context)
                : const Color(0xFFB8C2C4),
            onPressed: _register,
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
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.softSurface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorText == null
                  ? AppColors.border(context)
                  : Theme.of(context).colorScheme.error,
            ),
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
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
