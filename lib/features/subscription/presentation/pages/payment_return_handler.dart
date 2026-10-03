import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/subscription/data/services/subscription_api_service.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

/// Called by DeepLinkService when vendza://payment-return is received.
Future<void> handlePaymentReturn(BuildContext context, int paymentId) async {
  if (!context.mounted) return;
  await showAppPopup<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PaymentReturnPopup(paymentId: paymentId),
  );
}

// ── States ────────────────────────────────────────────────────────────────────

sealed class _VerifyState { const _VerifyState(); }
class _Verifying extends _VerifyState { const _Verifying(); }
class _Success extends _VerifyState {
  const _Success(this.planName);
  final String planName;
}
class _Pending extends _VerifyState { const _Pending(); }
class _Failed extends _VerifyState {
  const _Failed(this.message);
  final String message;
}

// ─────────────────────────────────────────────────────────────────────────────

class _PaymentReturnPopup extends StatefulWidget {
  const _PaymentReturnPopup({required this.paymentId});

  final int paymentId;

  @override
  State<_PaymentReturnPopup> createState() => _PaymentReturnPopupState();
}

class _PaymentReturnPopupState extends State<_PaymentReturnPopup> {
  _VerifyState _state = const _Verifying();
  int _attempts = 0;
  static const int _maxAttempts = 4;
  static const Duration _interval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _startVerification();
  }

  Future<void> _startVerification() async {
    setState(() { _state = const _Verifying(); _attempts = 0; });
    await _poll();
  }

  Future<void> _poll() async {
    while (_attempts < _maxAttempts) {
      _attempts++;
      try {
        final status =
            await subscriptionApiService.paymentStatus(widget.paymentId);
        if (status.subscriptionActive) {
          refreshActiveSubscription().ignore();
          if (mounted) {
            setState(() =>
                _state = _Success(status.plan?.title ?? 'Boutique Pro'));
          }
          return;
        }
        if (status.status == 'failed' || status.status == 'cancelled') {
          if (mounted) {
            setState(() => _state = const _Failed(
                "Votre paiement n'a pas été confirmé. Réessayez ou contactez le support."));
          }
          return;
        }
      } on ApiException catch (e) {
        if (mounted) setState(() => _state = _Failed(e.message));
        return;
      } on Object {
        // network glitch — keep trying
      }
      if (_attempts < _maxAttempts) await Future<void>.delayed(_interval);
    }
    if (mounted) setState(() => _state = const _Pending());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
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

// ── shared helpers ─────────────────────────────────────────────────────────────

Widget _iconCircle(BuildContext context, IconData icon, Color color) {
  return Center(
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 30),
    ),
  );
}

Widget _primaryButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
}) {
  final accent = AppColors.accent(context);
  return SizedBox(
    height: 48,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        label,
        style:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

Widget _secondaryButton(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
}) {
  return TextButton(
    onPressed: onPressed,
    child: Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ── Bodies ─────────────────────────────────────────────────────────────────────

class _VerifyingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: AppColors.accent(context),
              strokeWidth: 2.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Vérification en cours…',
          style: AppTextStyles.pageTitle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Nous confirmons votre paiement.\nCela prend quelques secondes.',
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
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
        _iconCircle(context, Icons.check_rounded, accent),
        const SizedBox(height: 18),
        Text(
          'Abonnement activé !',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary(context),
            height: 1.15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Votre plan $planName est maintenant actif.\nProfitez de toutes vos fonctionnalités.',
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _primaryButton(
          context,
          label: 'Accéder à mes boutiques',
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
        _iconCircle(context, Icons.hourglass_top_rounded, Colors.orange),
        const SizedBox(height: 18),
        Text(
          'Paiement en cours…',
          style: AppTextStyles.pageTitle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Votre paiement est en cours de traitement chez SasPay.\n'
          'Si vous avez bien payé, vérifiez dans quelques secondes.',
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _primaryButton(context, label: 'Vérifier maintenant', onPressed: onRetry),
        const SizedBox(height: 4),
        _secondaryButton(context, label: 'Fermer', onPressed: onClose),
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
        _iconCircle(context, Icons.error_outline_rounded, Colors.red),
        const SizedBox(height: 18),
        Text(
          'Paiement non confirmé',
          style: AppTextStyles.pageTitle(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: AppTextStyles.body(context),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _primaryButton(context, label: 'Réessayer', onPressed: onRetry),
        const SizedBox(height: 4),
        _secondaryButton(context, label: 'Fermer', onPressed: onClose),
      ],
    );
  }
}
