import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/home/presantation/pages/home.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/data/services/realtime_order_store.dart';
import 'package:vendza/features/order/presentation/helpers/order_list_presentation.dart';
import 'package:vendza/features/order/presentation/helpers/order_status_presentation.dart';
import 'package:vendza/shared/utils/date_time_label.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/loading/vendza_loading_state.dart';
import 'package:vendza/shared/widgets/media/context_image.dart';

const _ink = Color(0xFF0B3A40);
const _green = Color(0xFF2E8B57);
const _muted = Color(0xFF63777B);
const _line = Color(0xFFE5EEEA);
const _soft = Color(0xFFF7FAF8);

class BuyerOrdersPage extends StatefulWidget {
  const BuyerOrdersPage({
    super.key,
    this.inNavigation = false,
    this.onExploreProducts,
    this.api,
  });
  final bool inNavigation;
  final VoidCallback? onExploreProducts;
  final OrderApiService? api;
  @override
  State<BuyerOrdersPage> createState() => _BuyerOrdersPageState();
}

class _BuyerOrdersPageState extends State<BuyerOrdersPage> {
  late final OrderApiService _api = widget.api ?? OrderApiService();
  final Set<int> _hiddenIds = {};
  List<OrderModel> _orders = [];
  OrderSegmentKey _segment = OrderSegmentKey.active;
  OrderFilterKey _filter = OrderFilterKey.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    liveOrderStore.addListener(_sync);
    _load();
  }

  @override
  void dispose() {
    liveOrderStore.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() => _orders = List.of(liveOrderStore.value));
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
      replaceLiveOrders(orders);
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

  void _open(OrderModel order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => BuyerOrderDetailPage(
              orderId: order.id,
              api: _api,
              onHide: () {
                setState(() => _hiddenIds.add(order.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Commande masquée de votre historique.'),
                  ),
                );
              },
            ),
          ),
        )
        .then((_) {
          if (mounted) _load();
        });
  }

  void _explore() {
    if (widget.inNavigation) {
      widget.onExploreProducts?.call();
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final visible = buyerOrdersForSegment(
      _orders,
      _segment,
      hiddenIds: _hiddenIds,
      advancedFilter: _filter,
    );
    return Scaffold(
      backgroundColor: AppColors.isDark(context)
          ? AppColors.appBackground(context)
          : _soft,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.inNavigation,
        backgroundColor: AppColors.card(context),
        foregroundColor: AppColors.textPrimary(context),
        toolbarHeight: 84,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes commandes',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Vos achats, en un coup d’œil',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<OrderFilterKey>(
            tooltip: 'Filtrer',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (_) => orderAdvancedFilterOptions
                .map(
                  (option) => PopupMenuItem(
                    value: option.key,
                    child: Text(option.label),
                  ),
                )
                .toList(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const VendzaLoadingState(
                title: 'Chargement des commandes',
                message: 'Nous préparons vos commandes et leur état.',
                icon: Icons.receipt_long_outlined,
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.wifi_off_outlined,
                      title: 'Commandes indisponibles',
                      message: _error!,
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Réessayer'),
                    ),
                  ),
                ],
              )
            : _orders.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : 500,
                      ),
                      child: Center(
                        child: ResponsiveContent(
                          maxWidth: 440,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: AppColors.success(context),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Pas encore de commande',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Vos commandes apparaîtront ici. En attendant, découvrez les articles et les boutiques.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed:
                                      widget.inNavigation &&
                                          widget.onExploreProducts == null
                                      ? null
                                      : _explore,
                                  child: const Text('Découvrir les produits'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(15, 16, 15, 28),
                children: [
                  ResponsiveContent(
                    maxWidth: 720,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: buyerOrderSegmentOptions
                                .map(
                                  (option) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(option.label),
                                      selected: _segment == option.key,
                                      showCheckmark: false,
                                      onSelected: (_) =>
                                          setState(() => _segment = option.key),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (visible.isEmpty)
                          const EmptyStateWidget(
                            icon: Icons.filter_alt_off_outlined,
                            title: 'Aucune commande ici',
                            message:
                                'Changez d’onglet ou retirez le filtre avancé.',
                          ),
                        if (visible.isNotEmpty) ...[
                          _FocusCard(
                            order: visible.first,
                            onOpen: () => _open(visible.first),
                          ),
                          if (visible.length > 1) ...[
                            const Padding(
                              padding: EdgeInsets.only(top: 18, bottom: 10),
                              child: Text(
                                'Autres achats',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            ...visible
                                .skip(1)
                                .map(
                                  (order) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _OtherCard(
                                      order: order,
                                      onOpen: () => _open(order),
                                    ),
                                  ),
                                ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

String _money(double amount) => '${amount.toStringAsFixed(0)} CDF';
String _name(OrderModel order) => (order.storeName ?? '').trim().isEmpty
    ? 'Commande #${order.id}'
    : order.storeName!.trim();

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.order, required this.onOpen});
  final OrderModel order;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    final steps = orderTimelineSteps(order.status);
    final current = steps.indexWhere((step) => step.isCurrent);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: dark ? AppColors.card(context) : const Color(0xFFE6F2EA),
        border: Border.all(
          color: dark ? AppColors.border(context) : const Color(0xFFD0E7D8),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_name(order).toUpperCase()} · #${order.id}',
            style: const TextStyle(
              color: Color(0xFF346B53),
              fontSize: 11,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            orderStatusLabel(order.status),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            orderStatusDescription(order.status),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              steps.length,
              (index) => Expanded(
                child: Container(
                  height: 5,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: index <= current ? _green : const Color(0xFFC8DED3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(steps.first.label, style: const TextStyle(fontSize: 11)),
              Text(steps.last.label, style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          if (order.items.isNotEmpty)
            _ItemLine(
              item: order.items.first,
              subtitle:
                  '${_money(order.totalAmount)} · ${vendzaDateTimeLabel(order.createdAt)}',
            ),
          if (order.items.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '+ ${order.items.length - 1} autre(s) article(s)',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Voir le détail de la commande'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherCard extends StatelessWidget {
  const _OtherCard({required this.order, required this.onOpen});
  final OrderModel order;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.card(context),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border(context)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name(order),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '#${order.id} · ${vendzaDateTimeLabel(order.createdAt)} · ${order.items.length} article(s)',
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _money(order.totalAmount),
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ),
                const Text(
                  'Voir le détail →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item, required this.subtitle});
  final OrderItemModel item;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      VendzaContextImage(
        imageUrl: item.productImage,
        icon: Icons.shopping_bag_outlined,
        size: 38,
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.productName ?? 'Produit'} × ${item.quantity}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
      ),
    ],
  );
}

class BuyerOrderDetailPage extends StatefulWidget {
  const BuyerOrderDetailPage({
    super.key,
    required this.orderId,
    this.api,
    this.onHide,
  });
  final int orderId;
  final OrderApiService? api;
  final VoidCallback? onHide;
  @override
  State<BuyerOrderDetailPage> createState() => _BuyerOrderDetailPageState();
}

class _BuyerOrderDetailPageState extends State<BuyerOrderDetailPage> {
  late final OrderApiService _api = widget.api ?? OrderApiService();
  OrderModel? _order;
  String? _error;
  bool _loading = true;
  bool _updating = false;
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
      final order = await _api.orderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error is ApiException
              ? error.message
              : 'Impossible de charger cette commande.';
        });
      }
    }
  }

  Future<void> _cancel() async {
    final order = _order;
    if (order == null || !order.canBeCancelledByBuyer || _updating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conserver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer l’annulation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _updating = true);
    try {
      final updated = await _api.cancelOrder(order.id);
      if (!mounted) return;
      upsertLiveOrder(updated);
      setState(() => _order = updated);
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Impossible d’annuler la commande.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      backgroundColor: AppColors.isDark(context)
          ? AppColors.appBackground(context)
          : _soft,
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        foregroundColor: AppColors.textPrimary(context),
        toolbarHeight: 84,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande #${widget.orderId}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
            ),
            if (order != null)
              Text(
                '${_name(order)} · ${vendzaDateTimeLabel(order.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
          ],
        ),
        actions: [
          if (order != null &&
              (order.canBeCancelledByBuyer ||
                  (canHideOrder(order) && widget.onHide != null)))
            PopupMenuButton<String>(
              tooltip: 'Autres options',
              onSelected: (value) {
                if (value == 'cancel') {
                  _cancel();
                } else if (value == 'hide') {
                  widget.onHide?.call();
                  Navigator.of(context).pop();
                }
              },
              itemBuilder: (_) => [
                if (order.canBeCancelledByBuyer)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Annuler la commande'),
                  ),
                if (canHideOrder(order) && widget.onHide != null)
                  const PopupMenuItem(
                    value: 'hide',
                    child: Text('Masquer de l’historique'),
                  ),
              ],
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const VendzaLoadingState(
                title: 'Chargement de la commande',
                message: 'Nous préparons les détails.',
                icon: Icons.receipt_long_outlined,
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.wifi_off_outlined,
                      title: 'Commande indisponible',
                      message: _error!,
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Réessayer'),
                    ),
                  ),
                ],
              )
            : order == null
            ? const Center(child: Text('Commande indisponible'))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15),
                children: [
                  ResponsiveContent(
                    maxWidth: 720,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailCard(order: order),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            border: Border.all(
                              color: AppColors.border(context),
                            ),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Livraison',
                                style: TextStyle(
                                  color: AppColors.textPrimary(context),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text(
                                    'Adresse',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _muted,
                                    ),
                                  ),
                                  const Spacer(),
                                  Flexible(
                                    child: Text(
                                      (order.deliveryAddress ?? '')
                                              .trim()
                                              .isEmpty
                                          ? 'Adresse non renseignée'
                                          : order.deliveryAddress!.trim(),
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((order.customerNote ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text('Note : ${order.customerNote}'),
                              ],
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 12, left: 2),
                          child: Text(
                            'La date de livraison n’est pas encore disponible.',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.order});
  final OrderModel order;
  @override
  Widget build(BuildContext context) {
    final steps = orderTimelineSteps(order.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border.all(color: AppColors.border(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderStatusLabel(order.status),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      orderStatusDescription(order.status),
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          ...steps.map(
            (step) => IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: [
                        Icon(
                          step.isCurrent
                              ? Icons.circle
                              : step.isCompleted
                              ? Icons.circle
                              : Icons.radio_button_unchecked,
                          size: 17,
                          color: step.isCurrent
                              ? _green
                              : step.isCompleted
                              ? const Color(0xFF9ABFAA)
                              : const Color(0xFF9ABFAA),
                        ),
                        if (step != steps.last)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: const Color(0xFFD0E7D8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label == 'Prête'
                                ? 'Prête pour livraison ou retrait'
                                : step.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            step.isCurrent
                                ? 'Étape actuelle'
                                : step.isCompleted
                                ? 'Étape passée'
                                : 'À venir',
                            style: const TextStyle(fontSize: 10, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: _line),
          const SizedBox(height: 8),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemLine(item: item, subtitle: _name(order)),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total de la commande',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ),
              Text(
                _money(order.totalAmount),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
