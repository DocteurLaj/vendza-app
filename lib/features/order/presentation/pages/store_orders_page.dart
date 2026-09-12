import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/presentation/helpers/customer_contact_launcher.dart';
import 'package:vendza/features/order/presentation/helpers/order_status_presentation.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class StoreOrdersPage extends StatefulWidget {
  const StoreOrdersPage({super.key, required this.store});

  final ListStoreModel store;

  @override
  State<StoreOrdersPage> createState() => _StoreOrdersPageState();
}

class _StoreOrdersPageState extends State<StoreOrdersPage> {
  final _api = OrderApiService();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
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
      final orders = await _api.storeOrders(storeId: storeId);
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
            : 'Impossible de charger les commandes.';
      });
    }
  }

  Future<void> _updateStatus(OrderModel order, String status) async {
    final storeId = int.tryParse(widget.store.id);
    if (storeId == null || _updating) return;
    setState(() => _updating = true);
    try {
      final updated = await _api.updateStoreOrderStatus(
        storeId: storeId,
        orderId: order.id,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _orders = _orders
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newOrders = _orders
        .where((order) => order.status == 'pending')
        .length;
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        title: Text('Commandes · ${widget.store.name}'),
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
            : _orders.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'Aucune commande',
                      message: 'Les commandes de vos clients apparaitront ici.',
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ResponsiveContent(
                      maxWidth: 720,
                      child: _StoreOrdersSummary(
                        total: _orders.length,
                        pending: newOrders,
                      ),
                    );
                  }
                  final order = _orders[index - 1];
                  return ResponsiveContent(
                    maxWidth: 720,
                    child: _StoreOrderCard(
                      order: order,
                      updating: _updating,
                      onStatus: (status) => _updateStatus(order, status),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StoreOrdersSummary extends StatelessWidget {
  const _StoreOrdersSummary({required this.total, required this.pending});

  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          _SummaryItem(label: 'Total', value: '$total'),
          const SizedBox(width: 14),
          _SummaryItem(label: 'Nouvelles', value: '$pending'),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              pending == 0
                  ? 'Aucune commande en attente.'
                  : 'Traitez rapidement les commandes reçues.',
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StoreOrderCard extends StatelessWidget {
  const _StoreOrderCard({
    required this.order,
    required this.updating,
    required this.onStatus,
  });

  final OrderModel order;
  final bool updating;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final next = nextOrderStatus(order.status);
    final actionLabel = orderStatusActionLabel(order.status);
    final accent = orderStatusColor(order.status, context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(orderStatusIcon(order.status), color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${order.id}',
                      style: AppTextStyles.cardTitle(context),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} · ${order.items.length} article(s)',
                      style: TextStyle(color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            orderStatusDescription(order.status),
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          if ((order.contactPhone ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _CustomerContactRow(phone: order.contactPhone!.trim()),
          ],
          const SizedBox(height: 12),
          _OrderTimeline(status: order.status),
          if (next != null || order.status == 'pending') ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (next != null && actionLabel != null)
                  FilledButton.icon(
                    onPressed: updating ? null : () => onStatus(next),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(actionLabel),
                  ),
                if (order.status != 'cancelled' && order.status != 'delivered')
                  OutlinedButton.icon(
                    onPressed: updating ? null : () => onStatus('cancelled'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Annuler'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerContactRow extends StatelessWidget {
  const _CustomerContactRow({required this.phone});

  final String phone;

  Future<void> _open(BuildContext context) async {
    final opened = await openCustomerContact(phone);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir le contact client.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone_in_talk_outlined,
            color: AppColors.iconAccent(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact client',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _open(context),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Contacter'),
          ),
        ],
      ),
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
