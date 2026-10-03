import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/subscription/presentation/pages/subscription_page.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
bool isPlanLimitError(Object error) =>
    error is ApiException && error.isPlanLimitReached;

Future<bool> showUpgradeRequiredPopupFromError({
  required BuildContext context,
  required Object error,
}) async {
  if (error is! ApiException || !error.isPlanLimitReached) return false;
  await showUpgradeRequiredPopup(context: context, error: error);
  return true;
}

Future<void> showUpgradeRequiredPopup({
  required BuildContext context,
  required ApiException error,
}) {
  final detail = error.planLimitDetail ?? const <String, dynamic>{};
  final currentPlan = _planLabel(detail['current_plan']?.toString());
  final requiredPlan = _planLabel(detail['required_plan']?.toString());
  final message = detail['message']?.toString() ?? error.message;
  final featureName = _featureName(message);

  return showAppPopup<void>(
    context: context,
    builder: (dialogContext) =>
        _UpgradePopup(
          featureName: featureName,
          message: message,
          currentPlan: currentPlan,
          requiredPlan: requiredPlan,
        ),
  );
}

// ── helpers ────────────────────────────────────────────────────────────────────

String _planLabel(String? slug) {
  return switch (slug) {
    'free' => 'Gratuit',
    'starter' => 'Débutant',
    'active' => 'Actif',
    'pro' => 'Pro',
    _ => slug ?? '',
  };
}

/// Extracts a short feature name from the error message.
String _featureName(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('variante')) return 'Variantes produit';
  if (lower.contains('bannière') || lower.contains('banner')) return 'Bannière de boutique';
  if (lower.contains('collection')) return 'Collections';
  if (lower.contains('produit') || lower.contains('product')) return 'Produits';
  if (lower.contains('boutique') || lower.contains('store')) return 'Boutiques';
  if (lower.contains('image')) return 'Images produit';
  if (lower.contains('social') || lower.contains('lien')) return 'Liens sociaux';
  return 'Fonctionnalité';
}

// ─────────────────────────────────────────────────────────────────────────────

class _UpgradePopup extends StatelessWidget {
  const _UpgradePopup({
    required this.featureName,
    required this.message,
    required this.currentPlan,
    required this.requiredPlan,
  });

  final String featureName;
  final String message;
  final String currentPlan;
  final String requiredPlan;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Icon + header ────────────────────────────────────────────────
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: accent,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            featureName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary(context),
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // ── Message ─────────────────────────────────────────────────────
          Text(
            _shortMessage(message),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // ── Plan comparison ──────────────────────────────────────────────
          if (currentPlan.isNotEmpty && requiredPlan.isNotEmpty) ...[
            const SizedBox(height: 18),
            _PlanComparison(
              currentPlan: currentPlan,
              requiredPlan: requiredPlan,
              accent: accent,
              isDark: isDark,
              context: context,
            ),
          ],

          const SizedBox(height: 22),

          // ── CTA ──────────────────────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionPage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text(
                'Voir les offres',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Plus tard',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Trims the technical detail from API messages, keeps it short.
  String _shortMessage(String msg) {
    // Remove the "Passez à un plan supérieur" suffix if the comparison shows it
    if (requiredPlan.isNotEmpty) {
      final idx = msg.toLowerCase().indexOf('passez à');
      if (idx > 0) return msg.substring(0, idx).trim().trimRight();
    }
    // Hard limit
    if (msg.length > 120) return '${msg.substring(0, 118)}…';
    return msg;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan comparison chip row
// ─────────────────────────────────────────────────────────────────────────────

class _PlanComparison extends StatelessWidget {
  const _PlanComparison({
    required this.currentPlan,
    required this.requiredPlan,
    required this.accent,
    required this.isDark,
    required this.context,
  });

  final String currentPlan;
  final String requiredPlan;
  final Color accent;
  final bool isDark;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PlanChip(
          label: currentPlan,
          active: false,
          accent: accent,
          isDark: isDark,
          context: ctx,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: AppColors.textSecondary(ctx),
          ),
        ),
        _PlanChip(
          label: requiredPlan,
          active: true,
          accent: accent,
          isDark: isDark,
          context: ctx,
        ),
      ],
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.active,
    required this.accent,
    required this.isDark,
    required this.context,
  });

  final String label;
  final bool active;
  final Color accent;
  final bool isDark;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? accent.withValues(alpha: 0.12)
            : AppColors.card(ctx),
        border: Border.all(
          color: active ? accent : AppColors.border(ctx),
          width: active ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            active
                ? Icons.workspace_premium_rounded
                : Icons.workspace_premium_outlined,
            color: active ? accent : AppColors.textSecondary(ctx),
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? accent : AppColors.textSecondary(ctx),
            ),
          ),
        ],
      ),
    );
  }
}
