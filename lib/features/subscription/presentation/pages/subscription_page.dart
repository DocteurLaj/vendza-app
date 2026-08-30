import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';
import 'package:vendza/features/subscription/presentation/widgets/subscription_cart.dart';
import 'package:vendza/features/subscription/presentation/widgets/subscription_features.dart';
import 'package:vendza/features/subscription/presentation/widgets/text_intro.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

const String _subscriptionAboutUrl = 'https://vendza.app';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int selectedIndex = 1;
  bool _comingSoonShown = false;
  static const bool _offersEnabled = false;

  static final List<SubscriptionModel> _subscriptions = [
    SubscriptionModel(
      id: 'starter',
      title: 'Vendeur Débutant',
      price: 3000,
      duration: 'mois',
      subtitle: 'Au lieu de 10000 FC Prix Normal',
      features: [
        'Vente d’articles simples',
        'Nombre limité d’annonces',
        'Visibilité de base',
      ],
    ),
    SubscriptionModel(
      id: 'growth',
      title: 'Vendeur Actif',
      price: 5000,
      duration: 'mois',
      subtitle: 'Au lieu de 15000 FC Prix  Normal',
      features: [
        'Meilleure visibilité',
        'Plus de produits',
        'Meilleur positionnement',
        'Messagerie avec les clients',
      ],
    ),
    SubscriptionModel(
      id: 'business',
      title: 'Boutique Pro',
      price: 15000,
      duration: 'mois',
      subtitle: 'Au lieu de 25000 FC Prix  Normal',
      features: [
        'Produits illimités',
        'Position en tête de recherche',
        'Page boutique complète',
        'Tableau de bord analytique',
        'Support prioritaire',
      ],
    ),
  ];

  SubscriptionModel get _selectedSub => _subscriptions[selectedIndex];

  void _selectPlan(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _openAbout() async {
    final uri = Uri.parse(_subscriptionAboutUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir ce lien")),
      );
    }
  }

  Future<void> _showComingSoon({bool force = false}) async {
    if (!force && _comingSoonShown) return;
    if (!mounted) return;
    _comingSoonShown = true;
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
              Text(
                'Abonnements bientôt disponibles',
                style: AppTextStyles.pageTitle(context),
              ),
              const SizedBox(height: 10),
              Text(
                "L'application est actuellement disponible gratuitement. Les abonnements seront prochainement proposés aux utilisateurs souhaitant accéder à davantage de fonctionnalités professionnelles.",
                style: AppTextStyles.body(context),
              ),
              const SizedBox(height: 18),
              AppPopupActions(
                cancelLabel: 'En savoir plus',
                confirmLabel: 'Compris',
                onCancel: () {
                  Navigator.pop(context);
                  unawaited(_openAbout());
                },
                onConfirm: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSubscription() {
    unawaited(_showComingSoon(force: true));
  }

  Widget _comingSoonBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Abonnements bientôt disponibles',
                style: AppTextStyles.pageTitle(context),
              ),
              const SizedBox(height: 10),
              Text(
                "L'application est actuellement disponible gratuitement. Les abonnements seront prochainement proposés aux utilisateurs souhaitant accéder à davantage de fonctionnalités professionnelles.",
                style: AppTextStyles.body(context),
              ),
              const SizedBox(height: 18),
              AppPopupActions(
                cancelLabel: 'En savoir plus',
                confirmLabel: 'Compris',
                onCancel: () {
                  unawaited(_openAbout());
                },
                onConfirm: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement')),
      body: _offersEnabled
          ? LayoutBuilder(
        builder: (context, constraints) {
          final layoutMode = AppBreakpoints.authLayoutMode(
            constraints.maxWidth,
          );

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
                    selectedSub: _selectedSub,
                    onSelect: _selectPlan,
                    onConfirm: _confirmSubscription,
                  ),
                  AuthLayoutMode.medium ||
                  AuthLayoutMode.compact => _StackedSubscriptionLayout(
                    layoutMode: layoutMode,
                    subscriptions: _subscriptions,
                    selectedIndex: selectedIndex,
                    selectedSub: _selectedSub,
                    onSelect: _selectPlan,
                    onConfirm: _confirmSubscription,
                  ),
                },
              ),
            ),
          );
        },
      )
          : _comingSoonBody(context),
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
