import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/data/services/google_identity_service.dart';
import 'package:vendza/features/auth/data/services/google_sign_in_failure.dart';

Widget? buildGoogleSignInWebButton({
  required bool enabled,
  required AuthSessionService? sessionService,
  required ValueChanged<bool> onLoadingChanged,
  required FutureOr<void> Function() onAuthenticated,
  required ValueChanged<String> onError,
}) {
  return _GoogleSignInWebButton(
    enabled: enabled,
    sessionService: sessionService,
    onLoadingChanged: onLoadingChanged,
    onAuthenticated: onAuthenticated,
    onError: onError,
  );
}

class _GoogleSignInWebButton extends StatefulWidget {
  const _GoogleSignInWebButton({
    required this.enabled,
    required this.sessionService,
    required this.onLoadingChanged,
    required this.onAuthenticated,
    required this.onError,
  });

  final bool enabled;
  final AuthSessionService? sessionService;
  final ValueChanged<bool> onLoadingChanged;
  final FutureOr<void> Function() onAuthenticated;
  final ValueChanged<String> onError;

  @override
  State<_GoogleSignInWebButton> createState() => _GoogleSignInWebButtonState();
}

class _GoogleSignInWebButtonState extends State<_GoogleSignInWebButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    googleIdentityService.initialize().catchError((Object error) {
      if (mounted) widget.onError(_messageFor(error));
    });
    _subscription = GoogleSignIn.instance.authenticationEvents.listen(
      _handleAuthenticationEvent,
      onError: (Object error) {
        if (mounted) widget.onError(_messageFor(error));
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (!widget.enabled || _isLoading) return;
    if (event is! GoogleSignInAuthenticationEventSignIn) return;

    final idToken = event.user.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      widget.onError(
        'Google n’a pas retourné de jeton d’identité. '
        '${GoogleSignInFailureMapper.configHint}',
      );
      return;
    }

    _setLoading(true);
    try {
      await (widget.sessionService ?? authSessionService)
          .loginWithGoogleIdToken(idToken);
      if (!mounted) return;
      await widget.onAuthenticated();
    } on ApiException catch (error) {
      if (mounted) widget.onError(error.message);
    } on GoogleIdentityException catch (error) {
      if (mounted) widget.onError(error.message);
    } catch (error) {
      if (mounted) widget.onError(_messageFor(error));
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    setState(() => _isLoading = value);
    widget.onLoadingChanged(value);
  }

  String _messageFor(Object error) {
    if (error is GoogleIdentityException) return error.message;
    if (error is ApiException) return error.message;
    if (error is GoogleSignInException) {
      return GoogleSignInFailureMapper.map(error)?.message ??
          'Connexion Google annulée.';
    }
    return 'Connexion Google impossible.';
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      key: const ValueKey('google-sign-in-button'),
      absorbing: !widget.enabled || _isLoading,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            web_only.renderButton(
              configuration: web_only.GSIButtonConfiguration(
                theme: web_only.GSIButtonTheme.outline,
                size: web_only.GSIButtonSize.large,
                text: web_only.GSIButtonText.continueWith,
              ),
            ),
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x88FFFFFF),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
