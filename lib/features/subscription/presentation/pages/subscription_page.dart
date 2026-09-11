import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
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

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int selectedIndex = 0;
  bool _comingSoonShown = false;
  bool _loading = true;
  bool _enabled = false;
  String? _loadError;
  String _disabledMessage =
      "Les abonnements sont temporairement indisponibles.";
  List<SubscriptionModel> _subscriptions = const [];

  SubscriptionModel? get _selectedSub => _subscriptions.isEmpty
      ? null
      : _subscriptions[selectedIndex.clamp(0, _subscriptions.length - 1)];

  void _selectPlan(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadSubscriptions());
  }

  Future<void> _loadSubscriptions() async {
    try {
      final catalog = await SubscriptionApiService().catalog();
      if (!mounted) return;
      setState(() {
        _subscriptions = catalog.plans;
        _enabled = catalog.enabled;
        _disabledMessage = catalog.disabledMessage;
        _loading = false;
        _loadError = null;
        final currentId = catalog.currentPlan?.id;
        final currentIndex = currentId == null
            ? -1
            : _subscriptions.indexWhere((plan) => plan.id == currentId);
        selectedIndex = currentIndex >= 0 ? currentIndex : 0;
      });
      setActiveSubscription(catalog.currentPlan);
      if (!_enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showComingSoon());
        });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = "Impossible de charger les abonnements.";
      });
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
                'Abonnements indisponibles',
                style: AppTextStyles.pageTitle(context),
              ),
              const SizedBox(height: 10),
              Text(
                _disabledMessage,
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
  }

  void _confirmSubscription() {
    if (!_enabled) {
      unawaited(_showComingSoon(force: true));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("La souscription en ligne n'est pas encore disponible."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_loadError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_loadError!, textAlign: TextAlign.center),
              ),
            );
          }
          final selected = _selectedSub;
          if (selected == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _enabled
                      ? "Aucun plan disponible pour le moment."
                      : _disabledMessage,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
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
                    selectedSub: selected,
                    onSelect: _selectPlan,
                    onConfirm: _confirmSubscription,
                  ),
                  AuthLayoutMode.medium ||
                  AuthLayoutMode.compact => _StackedSubscriptionLayout(
                    layoutMode: layoutMode,
                    subscriptions: _subscriptions,
                    selectedIndex: selectedIndex,
                    selectedSub: selected,
                    onSelect: _selectPlan,
                    onConfirm: _confirmSubscription,
                  ),
                },
              ),
            ),
          );
        },
      ),
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
