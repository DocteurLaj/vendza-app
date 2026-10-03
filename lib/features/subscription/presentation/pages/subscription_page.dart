import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';
import 'package:vendza/features/subscription/data/services/subscription_api_service.dart';
import 'package:vendza/features/subscription/presentation/widgets/subscription_cart.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';

// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int selectedIndex = 0;
  bool _loading = true;
  String? _error;
  bool _paying = false;
  List<SubscriptionModel> _subscriptions = const [];

  SubscriptionModel? get _selectedSub {
    if (_subscriptions.isEmpty) return null;
    final safeIndex = selectedIndex.clamp(0, _subscriptions.length - 1);
    return _subscriptions[safeIndex];
  }

  void _selectPlan(int index) => setState(() => selectedIndex = index);

  String? get _activePlanCode =>
      activeSubscriptionStore.value?.plan.code;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlans());
  }

  Future<void> _loadPlans() async {
    setState(() { _loading = true; _error = null; });
    try {
      final plans = await refreshSubscriptionPlans();
      // Default selection: first paid plan
      final initialIndex = plans.indexWhere((p) => !p.isFree);
      if (!mounted) return;
      setState(() {
        _subscriptions = plans;
        selectedIndex = initialIndex >= 0 ? initialIndex : 0;
        _loading = false;
      });
      try { await refreshActiveSubscription(); } on Object { /* non-blocking */ }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : error.toString();
        _loading = false;
      });
    }
  }

  // ── checkout ──────────────────────────────────────────────────────────────

  Future<void> _startCheckout() async {
    final selected = _selectedSub;
    if (selected == null) return;

    if (selected.isFree) {
      await showAppPopup<void>(
        context: context,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Plan gratuit', style: AppTextStyles.pageTitle(ctx)),
              const SizedBox(height: 10),
              Text(
                'Le plan Gratuit est déjà actif sur votre compte.\n'
                'Choisissez un plan payant pour débloquer plus de fonctionnalités.',
                style: AppTextStyles.body(ctx),
              ),
              const SizedBox(height: 16),
              AppPopupActions(
                cancelLabel: 'Fermer',
                confirmLabel: 'Compris',
                onCancel: () => Navigator.pop(ctx),
                onConfirm: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _paying = true);
    try {
      final platform = (!kIsWeb) ? 'mobile' : 'web';
      final checkout = await subscriptionApiService.createCheckout(
        selected.code,
        platform: platform,
      );
      final uri = Uri.parse(checkout.checkoutUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir SasPay.")),
        );
        return;
      }
      if (!mounted) return;
      if (kIsWeb) {
        await _showPaymentVerificationDialog(checkout);
      } else {
        await _showWaitingForReturnDialog(checkout);
      }
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'Impossible de démarrer le paiement: $error';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _showWaitingForReturnDialog(
    SubscriptionCheckoutModel checkout,
  ) async {
    await showAppPopup<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent(dialogContext),
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Paiement en cours…',
                style: AppTextStyles.pageTitle(dialogContext),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Terminez votre paiement sur SasPay.\n'
                'Vous serez redirigé automatiquement.',
                style: AppTextStyles.body(dialogContext),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Fermer',
                  style: TextStyle(color: AppColors.textSecondary(dialogContext)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPaymentVerificationDialog(
    SubscriptionCheckoutModel checkout,
  ) async {
    await showAppPopup<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paiement ouvert dans SasPay',
                style: AppTextStyles.pageTitle(dialogContext),
              ),
              const SizedBox(height: 10),
              Text(
                'Terminez le paiement sur SasPay, puis revenez ici.',
                style: AppTextStyles.body(dialogContext),
              ),
              const SizedBox(height: 18),
              AppPopupActions(
                cancelLabel: 'Plus tard',
                confirmLabel: "J'ai payé, vérifier",
                onCancel: () => Navigator.pop(dialogContext),
                onConfirm: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final status = await subscriptionApiService.paymentStatus(
                      checkout.paymentId,
                    );
                    if (!mounted) return;
                    if (status.subscriptionActive) {
                      await refreshActiveSubscription();
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Abonnement ${status.plan?.title ?? ''} activé.',
                          ),
                        ),
                      );
                      return;
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Paiement encore en attente chez SasPay.'),
                      ),
                    );
                  } on Object catch (error) {
                    if (!mounted) return;
                    final message = error is ApiException
                        ? error.message
                        : 'Impossible de vérifier: $error';
                    messenger.showSnackBar(SnackBar(content: Text(message)));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── body ──────────────────────────────────────────────────────────────────

  Widget _stateBody(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.accent(context),
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.textSecondary(context),
              ),
              const SizedBox(height: 12),
              Text(
                'Impossible de charger les offres',
                style: AppTextStyles.sectionTitle(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context),
              ),
              const SizedBox(height: 16),
              AppBouton(text: 'Réessayer', onPressed: _loadPlans, enabled: true),
            ],
          ),
        ),
      );
    }
    if (_subscriptions.isEmpty || _selectedSub == null) {
      return Center(
        child: Text(
          'Aucune offre active pour le moment.',
          style: AppTextStyles.body(context),
        ),
      );
    }

    return _SubscriptionContent(
      subscriptions: _subscriptions,
      selectedIndex: selectedIndex,
      selectedSub: _selectedSub!,
      activePlanCode: _activePlanCode,
      paying: _paying,
      onSelect: _selectPlan,
      onConfirm: _startCheckout,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: const VendzaPageHeader.back(
        title: 'Abonnements',
        subtitle: 'Choisissez votre offre',
        icon: Icons.workspace_premium_outlined,
      ),
      body: _stateBody(context),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content layout
// ─────────────────────────────────────────────────────────────────────────────

class _SubscriptionContent extends StatelessWidget {
  const _SubscriptionContent({
    required this.subscriptions,
    required this.selectedIndex,
    required this.selectedSub,
    required this.activePlanCode,
    required this.paying,
    required this.onSelect,
    required this.onConfirm,
  });

  final List<SubscriptionModel> subscriptions;
  final int selectedIndex;
  final SubscriptionModel selectedSub;
  final String? activePlanCode;
  final bool paying;
  final ValueChanged<int> onSelect;
  final VoidCallback onConfirm;

  /// The "recommended" plan index — the first paid plan after Gratuit.
  int get _recommendedIndex {
    for (var i = 0; i < subscriptions.length; i++) {
      if (!subscriptions[i].isFree) return i;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        child: ResponsiveContent(
          maxWidth: 780,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _PageHeader(activePlanCode: activePlanCode),
              const SizedBox(height: 24),
              _PlanGrid(
                subscriptions: subscriptions,
                selectedIndex: selectedIndex,
                activePlanCode: activePlanCode,
                recommendedIndex: _recommendedIndex,
                onSelect: onSelect,
              ),
              const SizedBox(height: 28),
              _CtaSection(
                selectedSub: selectedSub,
                paying: paying,
                onConfirm: onConfirm,
              ),
              const SizedBox(height: 16),
              _SecurityNote(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page header
// ─────────────────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.activePlanCode});

  final String? activePlanCode;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + tagline
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Développez votre boutique',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary(context),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Accédez à plus de produits, collections et fonctionnalités.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(context),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Current plan banner (only if not free)
        if (activePlanCode != null && activePlanCode != 'free') ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.12 : 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Votre plan actuel est actif.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan grid / list
// ─────────────────────────────────────────────────────────────────────────────

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({
    required this.subscriptions,
    required this.selectedIndex,
    required this.activePlanCode,
    required this.recommendedIndex,
    required this.onSelect,
  });

  final List<SubscriptionModel> subscriptions;
  final int selectedIndex;
  final String? activePlanCode;
  final int recommendedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useGrid = screenWidth > 520 && subscriptions.length >= 3;

    if (useGrid) {
      // 2-column grid on wider screens
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < subscriptions.length; i++)
            SizedBox(
              width: (screenWidth - 32 - 12) / 2 > 280
                  ? (screenWidth - 32 - 12) / 2
                  : double.infinity,
              child: _planCard(i),
            ),
        ],
      );
    }

    // Single column (mobile default)
    return Column(
      children: [
        for (var i = 0; i < subscriptions.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _planCard(i),
        ],
      ],
    );
  }

  Widget _planCard(int i) {
    return SubscriptionCard(
      sub: subscriptions[i],
      isSelected: i == selectedIndex,
      isRecommended: i == recommendedIndex,
      isCurrent: subscriptions[i].code == activePlanCode,
      onTap: () => onSelect(i),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA
// ─────────────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection({
    required this.selectedSub,
    required this.paying,
    required this.onConfirm,
  });

  final SubscriptionModel selectedSub;
  final bool paying;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final label = selectedSub.isFree
        ? 'Continuer avec le plan Gratuit'
        : 'S\'abonner — ${selectedSub.formattedPrice}/mois';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: paying ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: accent.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: paying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        if (!selectedSub.isFree) ...[
          const SizedBox(height: 10),
          Text(
            'Annulable à tout moment · Paiement sécurisé via SasPay',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Security / trust note
// ─────────────────────────────────────────────────────────────────────────────

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: AppColors.textSecondary(context),
        ),
        const SizedBox(width: 5),
        Text(
          'Paiements sécurisés · Vendza ne stocke pas vos données bancaires',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
