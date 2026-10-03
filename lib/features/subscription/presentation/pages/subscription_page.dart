import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';
import 'package:vendza/features/subscription/data/services/subscription_api_service.dart';
import 'package:vendza/features/subscription/presentation/widgets/subscription_cart.dart';
import 'package:vendza/features/subscription/presentation/widgets/subscription_features.dart';
import 'package:vendza/features/subscription/presentation/widgets/text_intro.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';

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

  void _selectPlan(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlans());
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await refreshSubscriptionPlans();
      final initialIndex = plans.indexWhere((plan) => !plan.isFree);
      if (!mounted) return;
      setState(() {
        _subscriptions = plans;
        selectedIndex = initialIndex >= 0 ? initialIndex : 0;
        _loading = false;
      });
      try {
        await refreshActiveSubscription();
      } on Object {
        // The plan list is public. A missing seller session must not hide offers.
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException ? error.message : error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startCheckout() async {
    final selected = _selectedSub;
    if (selected == null || !mounted || _paying) return;
    if (selected.isFree) {
      await showAppPopup<void>(
        context: context,
        size: PopupSize.medium,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Offre gratuite', style: AppTextStyles.pageTitle(context)),
                const SizedBox(height: 10),
                Text(
                  'Votre compte utilise automatiquement l’offre gratuite quand aucun abonnement payant n’est actif.',
                  style: AppTextStyles.body(context),
                ),
                const SizedBox(height: 18),
                AppPopupActions(
                  cancelLabel: 'Fermer',
                  confirmLabel: 'Compris',
                  onCancel: () => Navigator.pop(context),
                  onConfirm: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _paying = true);
    try {
      // Detect platform: mobile = Android/iOS, web = everything else
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
      // On mobile the app receives a deep link on return \u2192 auto-popup.
      // On web we fall back to the manual verification dialog.
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

  /// Mobile-only: shown while SasPay is open.
  /// The app will detect the deep link return automatically and show
  /// the PaymentReturnHandler popup. This dialog is just a light reassurance.
  Future<void> _showWaitingForReturnDialog(
    SubscriptionCheckoutModel checkout,
  ) async {
    await showAppPopup<void>(
      context: context,
      size: PopupSize.medium,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
                'Vous serez redirigé automatiquement dans l\'application.',
                style: AppTextStyles.body(dialogContext),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Fermer',
                  style: TextStyle(
                    color: AppColors.textSecondary(dialogContext),
                  ),
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
      size: PopupSize.medium,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Padding(
          padding: const EdgeInsets.all(8),
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
                'Terminez le paiement sur SasPay, puis revenez ici pour activer votre abonnement.',
                style: AppTextStyles.body(dialogContext),
              ),
              const SizedBox(height: 18),
              AppPopupActions(
                cancelLabel: 'Plus tard',
                confirmLabel: 'J’ai payé, vérifier',
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
                        content: Text(
                          'Paiement encore en attente chez SasPay.',
                        ),
                      ),
                    );
                  } on Object catch (error) {
                    if (!mounted) return;
                    final message = error is ApiException
                        ? error.message
                        : 'Impossible de vérifier le paiement: $error';
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

  Widget _stateBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Impossible de charger les offres',
                style: AppTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context),
              ),
              const SizedBox(height: 16),
              AppBouton(
                text: 'Réessayer',
                onPressed: _loadPlans,
                enabled: true,
              ),
            ],
          ),
        ),
      );
    }
    if (_subscriptions.isEmpty || _selectedSub == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Aucune offre active pour le moment.',
            style: AppTextStyles.body(context),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutMode = AppBreakpoints.authLayoutMode(constraints.maxWidth);

        return SingleChildScrollView(
          child: ResponsiveContent(
            maxWidth: 920,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 32),
              child: switch (layoutMode) {
                AuthLayoutMode.expanded => _ExpandedSubscriptionLayout(
                  subscriptions: _subscriptions,
                  selectedIndex: selectedIndex,
                  selectedSub: _selectedSub!,
                  onSelect: _selectPlan,
                  onConfirm: _startCheckout,
                ),
                AuthLayoutMode.medium ||
                AuthLayoutMode.compact => _StackedSubscriptionLayout(
                  layoutMode: layoutMode,
                  subscriptions: _subscriptions,
                  selectedIndex: selectedIndex,
                  selectedSub: _selectedSub!,
                  onSelect: _selectPlan,
                  onConfirm: _startCheckout,
                ),
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VendzaPageHeader.back(
        title: 'Abonnement',
        subtitle: 'Options vendeur Vendza',
        icon: Icons.workspace_premium_outlined,
      ),
      body: _stateBody(context),
    );
  }
}

class _StackedSubscriptionLayout extends StatelessWidget {
  const _StackedSubscriptionLayout({
    required this.layoutMode,
    required this.subscriptions,
    required this.selectedIndex,
    required this.selectedSub,
    required this.onSelect,
    required this.onConfirm,
  });

  final AuthLayoutMode layoutMode;
  final List<SubscriptionModel> subscriptions;
  final int selectedIndex;
  final SubscriptionModel selectedSub;
  final ValueChanged<int> onSelect;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TextIntro(),
        const SizedBox(height: 10),
        _SubscriptionPlansSelector(
          layoutMode: layoutMode,
          subscriptions: subscriptions,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
        ),
        const SizedBox(height: 20),
        SubscriptionFeatures(selectedSub: selectedSub),
        const SizedBox(height: 24),
        _SubscriptionCta(onConfirm: onConfirm),
      ],
    );
  }
}

class _ExpandedSubscriptionLayout extends StatelessWidget {
  const _ExpandedSubscriptionLayout({
    required this.subscriptions,
    required this.selectedIndex,
    required this.selectedSub,
    required this.onSelect,
    required this.onConfirm,
  });

  final List<SubscriptionModel> subscriptions;
  final int selectedIndex;
  final SubscriptionModel selectedSub;
  final ValueChanged<int> onSelect;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              const TextIntro(),
              const SizedBox(height: 16),
              _SubscriptionPlansSelector(
                layoutMode: AuthLayoutMode.medium,
                subscriptions: subscriptions,
                selectedIndex: selectedIndex,
                onSelect: onSelect,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SubscriptionFeatures(selectedSub: selectedSub),
              const SizedBox(height: 24),
              _SubscriptionCta(onConfirm: onConfirm),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubscriptionPlansSelector extends StatelessWidget {
  const _SubscriptionPlansSelector({
    required this.layoutMode,
    required this.subscriptions,
    required this.selectedIndex,
    required this.onSelect,
  });

  final AuthLayoutMode layoutMode;
  final List<SubscriptionModel> subscriptions;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (layoutMode == AuthLayoutMode.compact) {
      return Column(
        children: [
          for (var index = 0; index < subscriptions.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            SubscriptionCard(
              sub: subscriptions[index],
              isSelected: index == selectedIndex,
              onTap: () => onSelect(index),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var index = 0; index < subscriptions.length; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == subscriptions.length - 1 ? 0 : 6,
              ),
              child: SubscriptionCard(
                sub: subscriptions[index],
                isSelected: index == selectedIndex,
                onTap: () => onSelect(index),
              ),
            ),
          ),
      ],
    );
  }
}

class _SubscriptionCta extends StatelessWidget {
  const _SubscriptionCta({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SizedBox(
          width: double.infinity,
          child: AppBouton(
            text: 'Prendre abonnement',
            onPressed: onConfirm,
            enabled: true,
          ),
        ),
      ),
    );
  }
}
