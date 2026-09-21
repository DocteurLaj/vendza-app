import 'package:vendza/features/order/data/models/order_model.dart';

enum OrderFilterKey {
  all,
  pending,
  confirmed,
  preparing,
  readyForDelivery,
  delivered,
  cancelled,
}

enum OrderSegmentKey { toProcess, active, completed, cancelled, history }

class OrderFilterOption {
  const OrderFilterOption({
    required this.key,
    required this.label,
    required this.statuses,
  });

  final OrderFilterKey key;
  final String label;
  final Set<String> statuses;
}

class OrderSegmentOption {
  const OrderSegmentOption({
    required this.key,
    required this.label,
    required this.statuses,
  });

  final OrderSegmentKey key;
  final String label;
  final Set<String> statuses;
}

class OrderSummary {
  const OrderSummary({
    required this.total,
    required this.newCount,
    required this.activeCount,
    required this.historyCount,
    required this.byStatus,
  });

  final int total;
  final int newCount;
  final int activeCount;
  final int historyCount;
  final Map<String, int> byStatus;
}

const orderHistoryStatuses = {'delivered', 'cancelled'};
const orderActiveStatuses = {
  'pending',
  'confirmed',
  'preparing',
  'ready_for_delivery',
};

const sellerOrderSegmentOptions = <OrderSegmentOption>[
  OrderSegmentOption(
    key: OrderSegmentKey.toProcess,
    label: 'À traiter',
    statuses: {'pending'},
  ),
  OrderSegmentOption(
    key: OrderSegmentKey.active,
    label: 'En cours',
    statuses: {'confirmed', 'preparing', 'ready_for_delivery'},
  ),
  OrderSegmentOption(
    key: OrderSegmentKey.history,
    label: 'Historique',
    statuses: orderHistoryStatuses,
  ),
];

const buyerOrderSegmentOptions = <OrderSegmentOption>[
  OrderSegmentOption(
    key: OrderSegmentKey.active,
    label: 'En cours',
    statuses: orderActiveStatuses,
  ),
  OrderSegmentOption(
    key: OrderSegmentKey.completed,
    label: 'Terminées',
    statuses: {'delivered'},
  ),
  OrderSegmentOption(
    key: OrderSegmentKey.cancelled,
    label: 'Annulées',
    statuses: {'cancelled'},
  ),
];

const orderAdvancedFilterOptions = <OrderFilterOption>[
  OrderFilterOption(
    key: OrderFilterKey.all,
    label: 'Tous les statuts',
    statuses: {},
  ),
  OrderFilterOption(
    key: OrderFilterKey.pending,
    label: 'Commande reçue',
    statuses: {'pending'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.confirmed,
    label: 'Confirmée',
    statuses: {'confirmed'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.preparing,
    label: 'En préparation',
    statuses: {'preparing'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.readyForDelivery,
    label: 'Prête',
    statuses: {'ready_for_delivery'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.delivered,
    label: 'Livrée',
    statuses: {'delivered'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.cancelled,
    label: 'Annulée',
    statuses: {'cancelled'},
  ),
];

List<OrderModel> sellerOrdersForSegment(
  List<OrderModel> orders,
  OrderSegmentKey segment, {
  required Set<int> hiddenIds,
  OrderFilterKey advancedFilter = OrderFilterKey.all,
}) {
  final option = sellerOrderSegmentOptions.firstWhere(
    (item) => item.key == segment,
  );
  return _filterOrders(
    orders,
    option.statuses,
    hiddenIds: hiddenIds,
    advancedFilter: advancedFilter,
  );
}

List<OrderModel> buyerOrdersForSegment(
  List<OrderModel> orders,
  OrderSegmentKey segment, {
  required Set<int> hiddenIds,
  OrderFilterKey advancedFilter = OrderFilterKey.all,
}) {
  final option = buyerOrderSegmentOptions.firstWhere(
    (item) => item.key == segment,
  );
  return _filterOrders(
    orders,
    option.statuses,
    hiddenIds: hiddenIds,
    advancedFilter: advancedFilter,
  );
}

List<OrderModel> applyAdvancedOrderFilter(
  List<OrderModel> orders,
  OrderFilterKey advancedFilter, {
  required Set<int> hiddenIds,
}) {
  return _filterOrders(
    orders,
    {},
    hiddenIds: hiddenIds,
    advancedFilter: advancedFilter,
  );
}

OrderSummary summarizeOrders(
  List<OrderModel> orders, {
  required Set<int> hiddenIds,
}) {
  final visible = orders
      .where((order) => !hiddenIds.contains(order.id))
      .toList();
  final byStatus = <String, int>{
    'pending': 0,
    'confirmed': 0,
    'preparing': 0,
    'ready_for_delivery': 0,
    'delivered': 0,
    'cancelled': 0,
  };
  for (final order in visible) {
    byStatus[order.status] = (byStatus[order.status] ?? 0) + 1;
  }
  return OrderSummary(
    total: visible.length,
    newCount: byStatus['pending'] ?? 0,
    activeCount: visible
        .where((order) => orderActiveStatuses.contains(order.status))
        .length,
    historyCount: visible
        .where((order) => orderHistoryStatuses.contains(order.status))
        .length,
    byStatus: byStatus,
  );
}

bool isHistoryOrder(OrderModel order) =>
    orderHistoryStatuses.contains(order.status);

bool canHideOrder(OrderModel order) => isHistoryOrder(order);

OrderFilterOption orderAdvancedFilterOption(OrderFilterKey key) {
  return orderAdvancedFilterOptions.firstWhere((option) => option.key == key);
}

List<OrderModel> _filterOrders(
  List<OrderModel> orders,
  Set<String> segmentStatuses, {
  required Set<int> hiddenIds,
  required OrderFilterKey advancedFilter,
}) {
  final advanced = orderAdvancedFilterOption(advancedFilter);
  return orders
      .where((order) => !hiddenIds.contains(order.id))
      .where(
        (order) =>
            segmentStatuses.isEmpty || segmentStatuses.contains(order.status),
      )
      .where(
        (order) =>
            advanced.statuses.isEmpty ||
            advanced.statuses.contains(order.status),
      )
      .toList(growable: false);
}
