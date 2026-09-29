import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_card.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_layout.dart';
import 'package:vendza/features/auth/presantation/widgets/input_widget.dart';
import 'package:vendza/navigation/main_page.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    required this.email,
    this.authApiService,
    this.authSessionService,
  });

  final String email;
  final AuthApiService? authApiService;
  final AuthSessionService? authSessionService;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _codeController = TextEditingController();
  late final AuthApiService _authApiService;
  late final AuthSessionService _authSessionService;
  bool _isVerifying = false;
  bool _isResending = false;
  DateTime? _lastResendAt;

  @override
  void initState() {
    super.initState();
    _authApiService = widget.authApiService ?? AuthApiService();
    _authSessionService = widget.authSessionService ?? authSessionService;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage('Entre le code à 6 chiffres.');
      return;
    }
    setState(() => _isVerifying = true);
    try {
      await _authApiService.verifyEmail(email: widget.email, code: code);
      await _authSessionService.restoreSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainPage()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    final last = _lastResendAt;
    if (last != null && DateTime.now().difference(last).inSeconds < 60) {
      _showMessage('Attends une minute avant de renvoyer le code.');
      return;
    }
    setState(() => _isResending = true);
    try {
      await _authApiService.resendEmailVerification(widget.email);
      _lastResendAt = DateTime.now();
      if (mounted) _showMessage('Nouveau code envoyé.');
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      compactHeaderHeightFactor: 0.36,
      child: AuthCard(
        title: 'Vérifie ton e-mail',
        subtitle:
            'Nous avons envoyé un code à 6 chiffres à ${widget.email}. Le code expire après quelques minutes.',
        heightFactor: 0.58,
        children: [
          MyTextField(
            controller: _codeController,
            hintText: 'Code à 6 chiffres',
            obscureText: false,
            iconPrefix: Icons.mark_email_read_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          AppBouton(
            text: 'Vérifier',
            loadingText: 'Vérification...',
            onPressed: _verify,
            enabled: !_isVerifying && !_isResending,
            isLoading: _isVerifying,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _isVerifying || _isResending ? null : _resend,
            icon: _isResending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Renvoyer le code'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent(context),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Si le code a expiré, demande simplement un nouveau code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}
