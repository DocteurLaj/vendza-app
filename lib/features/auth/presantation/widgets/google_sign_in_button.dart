import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/config/google_auth_config.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/data/services/google_identity_service.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    required this.onAuthenticated,
    this.enabled = true,
    this.foregroundColor,
    this.borderColor,
    this.onLoadingChanged,
    this.sessionService,
    super.key,
  });

  final FutureOr<void> Function() onAuthenticated;
  final bool enabled;
  final Color? foregroundColor;
  final Color? borderColor;
  final ValueChanged<bool>? onLoadingChanged;
  final AuthSessionService? sessionService;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!GoogleAuthConfig.isConfigured) return;
    setState(() => _isLoading = true);
    widget.onLoadingChanged?.call(true);
    try {
      final signedIn = await (widget.sessionService ?? authSessionService)
          .loginWithGoogle();
      if (!mounted) return;
      // null/false = user dismissed the account picker (or ambiguous Android
      // cancel). Do not claim "annulée" — config failures throw instead.
      if (!signedIn) return;
      await widget.onAuthenticated();
    } on GoogleIdentityException catch (error) {
      if (mounted) _showError(error.message);
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Connexion Google impossible.');
    } finally {
      widget.onLoadingChanged?.call(false);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleAuthConfig.isConfigured) {
      // Hide cleanly when OAuth clients / dart-defines are missing.
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey('google-sign-in-button'),
        onPressed: widget.enabled && !_isLoading ? _signIn : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.foregroundColor,
          side: widget.borderColor == null
              ? null
              : BorderSide(color: widget.borderColor!),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'G',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
        label: Text(
          _isLoading ? 'Connexion Google...' : 'Continuer avec Google',
        ),
      ),
    );
  }
}
