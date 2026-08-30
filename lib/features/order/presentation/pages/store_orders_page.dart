import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
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
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        title: const Text('Commandes'),
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
                itemCount: _orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = _orders[index];
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

class _StoreOrderCard extends StatelessWidget {
  const _StoreOrderCard({
    required this.order,
    required this.updating,
    required this.onStatus,
  });

  final OrderModel order;
  final bool updating;
  final ValueChanged<String> onStatus;

  static const _nextStatus = {
    'pending': 'confirmed',
    'confirmed': 'preparing',
    'preparing': 'ready_for_delivery',
    'ready_for_delivery': 'delivered',
  };

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus[order.status];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commande #${order.id}',
            style: AppTextStyles.cardTitle(context),
          ),
          const SizedBox(height: 4),
          Text(
            '${order.status} · ${order.totalAmount.toStringAsFixed(0)} · ${order.items.length} article(s)',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
          if (next != null || order.status == 'pending') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (next != null)
                  FilledButton(
                    onPressed: updating ? null : () => onStatus(next),
                    child: Text('Passer a $next'),
                  ),
                if (order.status != 'cancelled' && order.status != 'delivered')
                  OutlinedButton(
                    onPressed: updating ? null : () => onStatus('cancelled'),
                    child: const Text('Annuler'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
