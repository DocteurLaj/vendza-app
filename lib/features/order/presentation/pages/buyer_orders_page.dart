import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/presentation/helpers/order_list_presentation.dart';
import 'package:vendza/features/order/presentation/helpers/order_status_presentation.dart';
import 'package:vendza/shared/utils/date_time_label.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/media/context_image.dart';

class BuyerOrdersPage extends StatefulWidget {
  const BuyerOrdersPage({super.key});

  @override
  State<BuyerOrdersPage> createState() => _BuyerOrdersPageState();
}

class _BuyerOrdersPageState extends State<BuyerOrdersPage> {
  final _api = OrderApiService();
  final Set<int> _expandedIds = {};
  final Set<int> _hiddenIds = {};
  List<OrderModel> _orders = [];
  OrderFilterKey _filter = OrderFilterKey.all;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _api.customerOrders(pageSize: 100);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is ApiException
            ? error.message
            : 'Impossible de charger vos commandes.';
      });
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final updated = await _api.cancelOrder(order.id);
      if (!mounted) return;
      setState(() {
        _orders = _orders
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
        _expandedIds.add(updated.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Commande annulée.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _hideOrder(OrderModel order) {
    setState(() {
      _hiddenIds.add(order.id);
      _expandedIds.remove(order.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande masquée de votre historique.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = summarizeOrders(_orders, hiddenIds: _hiddenIds);
    final sections = buyerOrderSections(
      _orders,
      _filter,
      hiddenIds: _hiddenIds,
    );
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        title: const Text('Mes commandes'),
        backgroundColor: AppColors.appBackground(context),
        foregroundColor: AppColors.textPrimary(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.wifi_off_outlined,
                      title: 'Commandes indisponibles',
                      message: _error!,
                    ),
                  ),
                ],
              )
            : summary.total == 0
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'Aucune commande',
                      message: 'Vous n’avez encore effectué aucune commande.',
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ResponsiveContent(
                    maxWidth: 720,
                    child: _OrdersHeader(
                      title: 'Suivi premium',
                      subtitle:
                          '${summary.activeCount} active(s) · ${summary.historyCount} historique',
                      summary: summary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ResponsiveContent(
                    maxWidth: 720,
                    child: _OrderFilterBar(
                      selected: _filter,
                      onSelected: (filter) => setState(() => _filter = filter),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (sections.every((section) => section.orders.isEmpty))
                    ResponsiveContent(
                      maxWidth: 720,
                      child: EmptyStateWidget(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Aucune commande dans ce filtre',
                        message:
                            'Choisissez un autre statut pour afficher vos commandes.',
                      ),
                    )
                  else
                    ...sections.expand(
                      (section) => [
                        ResponsiveContent(
                          maxWidth: 720,
                          child: _OrderSectionHeader(section: section),
                        ),
                        const SizedBox(height: 8),
                        ...section.orders.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ResponsiveContent(
                              maxWidth: 720,
                              child: _BuyerOrderCard(
                                order: order,
                                expanded: _expandedIds.contains(order.id),
                                updating: _updating,
                                onToggle: () => setState(() {
                                  if (!_expandedIds.add(order.id)) {
                                    _expandedIds.remove(order.id);
                                  }
                                }),
                                onCancel: order.canBeCancelledByBuyer
                                    ? () => _cancelOrder(order)
                                    : null,
                                onHide: canHideOrder(order)
                                    ? () => _hideOrder(order)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _BuyerOrderCard extends StatelessWidget {
  const _BuyerOrderCard({
    required this.order,
    required this.expanded,
    required this.updating,
    required this.onToggle,
    this.onCancel,
    this.onHide,
  });

  final OrderModel order;
  final bool expanded;
  final bool updating;
  final VoidCallback onToggle;
  final VoidCallback? onCancel;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    return _PremiumOrderShell(
      order: order,
      expanded: expanded,
      onToggle: onToggle,
      collapsedSubtitle:
          '${vendzaDateTimeLabel(order.createdAt)} · ${order.totalAmount.toStringAsFixed(0)} · ${order.items.length} article(s)',
      expandedChildren: [
        _OrderItemsPreview(items: order.items),
        const SizedBox(height: 12),
        _InfoBox(
          icon: Icons.location_on_outlined,
          title: 'Adresse de livraison',
          value: (order.deliveryAddress ?? '').trim().isEmpty
              ? 'Adresse non renseignée'
              : order.deliveryAddress!.trim(),
        ),
        if ((order.customerNote ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoBox(
            icon: Icons.sticky_note_2_outlined,
            title: 'Note au vendeur',
            value: order.customerNote!.trim(),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          orderStatusDescription(order.status),
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _OrderTimeline(status: order.status),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onCancel != null)
              OutlinedButton.icon(
                onPressed: updating ? null : onCancel,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Annuler la commande'),
              ),
            if (onHide != null)
              TextButton.icon(
                onPressed: onHide,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Masquer de l’historique'),
              ),
          ],
        ),
      ],
    );
  }
}

class _PremiumOrderShell extends StatelessWidget {
  const _PremiumOrderShell({
    required this.order,
    required this.expanded,
    required this.onToggle,
    required this.collapsedSubtitle,
    required this.expandedChildren,
  });

  final OrderModel order;
  final bool expanded;
  final VoidCallback onToggle;
  final String collapsedSubtitle;
  final List<Widget> expandedChildren;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.16 : 0.045,
            ),
            blurRadius: expanded ? 22 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Row(
              children: [
                VendzaContextImage(
                  imageUrl: order.storeImage,
                  icon: orderStatusIcon(order.status),
                  size: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeName == null
                            ? 'Commande #${order.id}'
                            : '${order.storeName} · #${order.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        collapsedSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(status: order.status),
                IconButton(
                  tooltip: expanded ? 'Plier' : 'Déplier',
                  onPressed: onToggle,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: expandedChildren,
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.title,
    required this.subtitle,
    required this.summary,
  });

  final String title;
  final String subtitle;
  final OrderSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent(context).withValues(alpha: 0.18),
            AppColors.card(context),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.cardTitle(context)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(label: 'Total', value: '${summary.total}'),
              _MetricChip(label: 'Actives', value: '${summary.activeCount}'),
              _MetricChip(
                label: 'Historique',
                value: '${summary.historyCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderFilterBar extends StatelessWidget {
  const _OrderFilterBar({required this.selected, required this.onSelected});

  final OrderFilterKey selected;
  final ValueChanged<OrderFilterKey> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: orderFilterOptions
            .map(
              (option) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option.label),
                  selected: selected == option.key,
                  onSelected: (_) => onSelected(option.key),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _OrderSectionHeader extends StatelessWidget {
  const _OrderSectionHeader({required this.section});

  final OrderSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title, style: AppTextStyles.cardTitle(context)),
                Text(
                  section.subtitle,
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              ],
            ),
          ),
          _MetricChip(label: 'Commandes', value: '${section.orders.length}'),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Text(
        '$label · $value',
        style: TextStyle(
          color: AppColors.textPrimary(context),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.iconAccent(context), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemsPreview extends StatelessWidget {
  const _OrderItemsPreview({required this.items});

  final List<OrderItemModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  VendzaContextImage(
                    imageUrl: item.productImage,
                    icon: Icons.shopping_bag_outlined,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.productName ?? 'Produit'} × ${item.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    item.totalPrice.toStringAsFixed(0),
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final steps = orderTimelineSteps(status);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: steps
          .map((step) {
            final color = orderStatusColor(step.status, context);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  step.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 15,
                  color: step.isCompleted
                      ? color
                      : AppColors.textSecondary(
                          context,
                        ).withValues(alpha: 0.45),
                ),
                const SizedBox(width: 4),
                Text(
                  step.label,
                  style: TextStyle(
                    color: step.isCurrent
                        ? color
                        : AppColors.textSecondary(context),
                    fontSize: 11,
                    fontWeight: step.isCurrent
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
              ],
            );
          })
          .toList(growable: false),
    );
  }
}
