import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/subscription/data/services/subscription_api_service.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

/// Called by DeepLinkService when vendza://payment-return is received.
/// Shows an automatic, reassuring UX:
///   1. Spinner while verifying
///   2. Success screen if paid
///   3. "Still pending" with manual retry if not yet confirmed
Future<void> handlePaymentReturn(BuildContext context, int paymentId) async {
  if (!context.mounted) return;
  await showAppPopup<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PaymentReturnPopup(paymentId: paymentId),
  );
}

// ── States ────────────────────────────────────────────────────────────────────

sealed class _VerifyState {
  const _VerifyState();
}

class _Verifying extends _VerifyState {
  const _Verifying();
}

class _Success extends _VerifyState {
  const _Success(this.planName);
  final String planName;
}

class _Pending extends _VerifyState {
  const _Pending();
}

class _Failed extends _VerifyState {
  const _Failed(this.message);
  final String message;
}

// ── Widget ────────────────────────────────────────────────────────────────────

class _PaymentReturnPopup extends StatefulWidget {
  const _PaymentReturnPopup({required this.paymentId});

  final int paymentId;

  @override
  State<_PaymentReturnPopup> createState() => _PaymentReturnPopupState();
}

class _PaymentReturnPopupState extends State<_PaymentReturnPopup> {
  _VerifyState _state = const _Verifying();
  int _attempts = 0;
  static const int _maxPollingAttempts = 4;
  static const Duration _pollInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _startVerification();
  }

  Future<void> _startVerification() async {
    setState(() => _state = const _Verifying());
    await _poll();
  }

  Future<void> _poll() async {
    _attempts = 0;
    while (_attempts < _maxPollingAttempts) {
      _attempts++;
      try {
        final status =
            await subscriptionApiService.paymentStatus(widget.paymentId);
        if (status.subscriptionActive) {
          // Refresh subscription context in the background
          refreshActiveSubscription().ignore();
          if (mounted) {
            setState(
              () => _state = _Success(status.plan?.title ?? 'Boutique Pro'),
            );
          }
          return;
        }
        if (status.status == 'failed' || status.status == 'cancelled') {
          if (mounted) {
            setState(
              () => _state = _Failed(
                'Votre paiement n\'a pas été confirmé par SasPay. '
                'Réessayez ou contactez le support.',
              ),
            );
          }
          return;
        }
      } on ApiException catch (e) {
        if (mounted) setState(() => _state = _Failed(e.message));
        return;
      } on Object {
        // Network glitch — keep trying
      }
      // Wait before next attempt
      if (_attempts < _maxPollingAttempts) {
        await Future<void>.delayed(_pollInterval);
      }
    }
    // All attempts exhausted — show pending state
    if (mounted) setState(() => _state = const _Pending());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: switch (_state) {
        _Verifying() => _VerifyingBody(),
        _Success(:final planName) => _SuccessBody(
            planName: planName,
            onClose: () => Navigator.pop(context),
          ),
        _Pending() => _PendingBody(
            onRetry: _startVerification,
            onClose: () => Navigator.pop(context),
          ),
        _Failed(:final message) => _FailedBody(
            message: message,
            onRetry: _startVerification,
            onClose: () => Navigator.pop(context),
          ),
      },
    );
  }
}

// ── Bodies ────────────────────────────────────────────────────────────────────

class _VerifyingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        CircularProgressIndicator(
          color: AppColors.accent(context),
          strokeWidth: 2.5,
        ),
        const SizedBox(height: 20),
        Text(
          'Vérification du paiement…',
          style: AppTextStyles.sectionTitle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Nous confirmons votre paiement avec SasPay.\nCela prend quelques secondes.',
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.planName, required this.onClose});

  final String planName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: accent,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Abonnement activé !',
          style: AppTextStyles.pageTitle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Votre plan $planName est maintenant actif.\nProfitez de toutes vos fonctionnalités.',
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppBouton(
          text: 'Accéder à mes boutiques',
          enabled: true,
          onPressed: onClose,
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _PendingBody extends StatelessWidget {
  const _PendingBody({required this.onRetry, required this.onClose});

  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Colors.orange,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Paiement en cours…',
          style: AppTextStyles.pageTitle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Votre paiement est en cours de traitement chez SasPay.\n'
          'Si vous avez bien payé, attendez quelques secondes et vérifiez.',
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppBouton(
          text: 'Vérifier maintenant',
          enabled: true,
          onPressed: onRetry,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onClose,
          child: Text(
            'Fermer',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
      ],
    );
  }
}

class _FailedBody extends StatelessWidget {
  const _FailedBody({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Paiement non confirmé',
          style: AppTextStyles.pageTitle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppBouton(
          text: 'Réessayer',
          enabled: true,
          onPressed: onRetry,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onClose,
          child: Text(
            'Fermer',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
      ],
    );
  }
}
