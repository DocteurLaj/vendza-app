import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/data/services/realtime_order_store.dart';
import 'package:vendza/features/order/presentation/helpers/customer_contact_launcher.dart';
import 'package:vendza/features/order/presentation/helpers/order_list_presentation.dart';
import 'package:vendza/features/order/presentation/helpers/order_status_presentation.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/utils/date_time_label.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';
import 'package:vendza/shared/widgets/loading/vendza_loading_state.dart';
import 'package:vendza/shared/widgets/media/context_image.dart';

class StoreOrdersPage extends StatefulWidget {
  const StoreOrdersPage({super.key, required this.store, this.apiService});
  final ListStoreModel store;
  final OrderApiService? apiService;

  @override
  State<StoreOrdersPage> createState() => _StoreOrdersPageState();
}

class _StoreOrdersPageState extends State<StoreOrdersPage> {
  late final OrderApiService _api = widget.apiService ?? OrderApiService();
  final Set<int> _hiddenIds = {};
  List<OrderModel> _orders = [];
  OrderSegmentKey _segment = OrderSegmentKey.toProcess;
  OrderFilterKey _filter = OrderFilterKey.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    liveOrderStore.addListener(_syncLiveOrders);
    _load();
  }

  @override
  void dispose() {
    liveOrderStore.removeListener(_syncLiveOrders);
    super.dispose();
  }

  void _syncLiveOrders() {
    final storeId = int.tryParse(widget.store.id);
    if (mounted && storeId != null) {
      setState(() => _orders = liveOrdersForStore(storeId));
    }
  }

  Future<void> _load() async {
    final storeId = int.tryParse(widget.store.id);
    if (storeId == null) {
      setState(() {
        _loading = false;
        _error = 'Identifiant de boutique invalide.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _api.storeOrders(storeId: storeId, pageSize: 100);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
      replaceLiveOrdersForStore(storeId, orders);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is ApiException
            ? error.message
            : 'Impossible de charger les commandes.';
      });
    }
  }

  void _inspect(OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _StoreOrderDetailPage(
          order: order,
          store: widget.store,
          onStatus: (status) => _updateStatus(order.id, status),
          onHide: canHideOrder(order)
              ? () {
                  setState(() => _hiddenIds.add(order.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Commande masquée de l’historique vendeur.',
                      ),
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }

  Future<OrderModel?> _updateStatus(int orderId, String status) async {
    final storeId = int.tryParse(widget.store.id);
    if (storeId == null) return null;
    try {
      final updated = await _api.updateStoreOrderStatus(
        storeId: storeId,
        orderId: orderId,
        status: status,
      );
      if (!mounted) return null;
      setState(
        () => _orders = _orders
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false),
      );
      upsertLiveOrder(updated);
      return updated;
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Impossible de modifier la commande.',
            ),
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = summarizeOrders(_orders, hiddenIds: _hiddenIds);
    final visible = sellerOrdersForSegment(
      _orders,
      _segment,
      hiddenIds: _hiddenIds,
      advancedFilter: _filter,
    );
    final label = sellerOrderSegmentOptions
        .firstWhere((option) => option.key == _segment)
        .label;
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: VendzaPageHeader.back(
        title: 'Commandes reçues',
        subtitle: widget.store.name,
        icon: Icons.storefront_outlined,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const VendzaLoadingState(
                title: 'Chargement des commandes',
                message: 'Nous préparons les commandes de cette boutique.',
                icon: Icons.storefront_outlined,
              )
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
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ResponsiveContent(
                    maxWidth: 720,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (summary.newCount > 0)
                          _Panel(
                            color: AppColors.accent(
                              context,
                            ).withValues(alpha: .12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${summary.newCount} ${summary.newCount == 1 ? 'commande à traiter' : 'commandes à traiter'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ouvrez une commande pour vérifier les détails avant de la confirmer.',
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final option in sellerOrderSegmentOptions)
                                Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: ChoiceChip(
                                    showCheckmark: false,
                                    selected: _segment == option.key,
                                    label: Text(
                                      option.key == OrderSegmentKey.toProcess &&
                                              summary.newCount > 0
                                          ? '${option.label}  ${summary.newCount}'
                                          : option.label,
                                    ),
                                    onSelected: (_) =>
                                        setState(() => _segment = option.key),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            PopupMenuButton<OrderFilterKey>(
                              tooltip: 'Filtrer',
                              onSelected: (value) =>
                                  setState(() => _filter = value),
                              itemBuilder: (_) => [
                                for (final option in orderAdvancedFilterOptions)
                                  PopupMenuItem(
                                    value: option.key,
                                    child: Text(option.label),
                                  ),
                              ],
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Filtrer'),
                                    SizedBox(width: 4),
                                    Icon(Icons.tune, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (summary.total == 0)
                          const EmptyStateWidget(
                            icon: Icons.receipt_long_outlined,
                            title: 'Aucune commande',
                            message:
                                'Les commandes de vos clients apparaîtront ici.',
                          )
                        else if (visible.isEmpty)
                          const EmptyStateWidget(
                            icon: Icons.filter_alt_off_outlined,
                            title: 'Aucune commande ici',
                            message:
                                'Changez d’onglet ou retirez le filtre avancé.',
                          )
                        else
                          for (final order in visible)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SellerOrderCard(
                                order: order,
                                onInspect: () => _inspect(order),
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

class _SellerOrderCard extends StatelessWidget {
  const _SellerOrderCard({required this.order, required this.onInspect});
  final OrderModel order;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final first = order.items.isEmpty ? null : order.items.first;
    final quantity = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    return _Panel(
      child: InkWell(
        onTap: onInspect,
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
                        'Commande #${order.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${vendzaDateTimeLabel(order.createdAt)} · $quantity ${quantity == 1 ? 'article' : 'articles'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            if (first != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  VendzaContextImage(
                    imageUrl: first.productImage,
                    icon: Icons.inventory_2_outlined,
                    size: 48,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${first.productName ?? 'Produit'} × ${first.quantity}${order.items.length > 1 ? ' + ${order.items.length - 1}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          (order.deliveryAddress ?? '').trim().isEmpty
                              ? 'Adresse non renseignée'
                              : 'Adresse renseignée',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} CDF',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.status == 'pending'
                        ? 'Vérifier avant de confirmer'
                        : orderStatusDescription(order.status),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                TextButton(onPressed: onInspect, child: const Text('Examiner')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreOrderDetailPage extends StatefulWidget {
  const _StoreOrderDetailPage({
    required this.order,
    required this.store,
    required this.onStatus,
    this.onHide,
  });
  final OrderModel order;
  final ListStoreModel store;
  final Future<OrderModel?> Function(String status) onStatus;
  final VoidCallback? onHide;

  @override
  State<_StoreOrderDetailPage> createState() => _StoreOrderDetailPageState();
}

class _StoreOrderDetailPageState extends State<_StoreOrderDetailPage> {
  late OrderModel _order = widget.order;
  bool _updating = false;

  Future<void> _changeStatus(String status) async {
    if (_updating) return;
    setState(() => _updating = true);
    final updated = await widget.onStatus(status);
    if (!mounted) return;
    setState(() {
      if (updated != null) _order = updated;
      _updating = false;
    });
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text(
          'Cette action modifiera le statut de la commande pour le client.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conserver la commande'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer l’annulation'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _changeStatus('cancelled');
  }

  Future<void> _contact() async {
    final opened = await openCustomerContact(_order.contactPhone!.trim());
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir le contact client.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = nextOrderStatus(_order.status);
    final action = orderStatusActionLabel(_order.status);
    final address = (_order.deliveryAddress ?? '').trim();
    final phone = (_order.contactPhone ?? '').trim();
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: VendzaPageHeader.back(
        title: 'Commande #${_order.id}',
        subtitle:
            '${widget.store.name} · ${vendzaDateTimeLabel(_order.createdAt)} · ${_order.totalAmount.toStringAsFixed(0)} CDF',
        icon: Icons.receipt_long_outlined,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ResponsiveContent(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'État de la commande',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          _StatusChip(status: _order.status),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        orderStatusLabel(_order.status),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _order.status == 'pending'
                            ? 'Vérifiez les informations avant de confirmer.'
                            : orderStatusDescription(_order.status),
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final step in orderTimelineSteps(_order.status))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Icon(
                                step.isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: step.isCompleted
                                    ? AppColors.accent(context)
                                    : AppColors.textSecondary(context),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                step.label,
                                style: TextStyle(
                                  fontWeight: step.isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 24),
                      for (final item in _order.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              VendzaContextImage(
                                imageUrl: item.productImage,
                                icon: Icons.inventory_2_outlined,
                                size: 48,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${item.productName ?? 'Produit'} × ${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text('${item.totalPrice.toStringAsFixed(0)} CDF'),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total · ${_order.totalAmount.toStringAsFixed(0)} CDF',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Livraison et client',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Adresse',
                        value: address.isEmpty
                            ? 'Adresse non renseignée'
                            : address,
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        label: 'Téléphone',
                        value: phone.isEmpty ? 'Numéro non renseigné' : phone,
                      ),
                      if ((_order.customerNote ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailRow(
                          label: 'Note client',
                          value: _order.customerNote!.trim(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (next != null && action != null)
                  FilledButton(
                    onPressed: _updating ? null : () => _changeStatus(next),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          action == 'Confirmer'
                              ? 'Confirmer la commande'
                              : '$action la commande',
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                if (phone.isNotEmpty)
                  TextButton(
                    onPressed: _contact,
                    child: const Text('Contacter le client'),
                  ),
                if (_order.status != 'cancelled' &&
                    _order.status != 'delivered') ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _updating ? null : _cancel,
                    child: const Text('Annuler la commande'),
                  ),
                ],
                if (widget.onHide != null && canHideOrder(_order))
                  TextButton(
                    onPressed: () {
                      widget.onHide!();
                      Navigator.pop(context);
                    },
                    child: const Text('Masquer de l’historique'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: AppColors.textSecondary(context))),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status == 'pending' ? 'À confirmer' : orderStatusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.color});
  final Widget child;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? AppColors.card(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border(context)),
    ),
    child: child,
  );
}
