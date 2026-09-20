import 'package:vendza/features/order/data/models/order_model.dart';

enum OrderFilterKey {
  all,
  newOrders,
  active,
  confirmed,
  preparing,
  readyForDelivery,
  delivered,
  cancelled,
  history,
}

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

class OrderSection {
  const OrderSection({
    required this.title,
    required this.subtitle,
    required this.orders,
  });

  final String title;
  final String subtitle;
  final List<OrderModel> orders;
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

const orderFilterOptions = <OrderFilterOption>[
  OrderFilterOption(key: OrderFilterKey.all, label: 'Tous', statuses: {}),
  OrderFilterOption(
    key: OrderFilterKey.newOrders,
    label: 'Nouvelles',
    statuses: {'pending'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.active,
    label: 'En cours',
    statuses: orderActiveStatuses,
  ),
  OrderFilterOption(
    key: OrderFilterKey.confirmed,
    label: 'Confirmées',
    statuses: {'confirmed'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.preparing,
    label: 'Préparation',
    statuses: {'preparing'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.readyForDelivery,
    label: 'Prêtes',
    statuses: {'ready_for_delivery'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.delivered,
    label: 'Livrées',
    statuses: {'delivered'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.cancelled,
    label: 'Annulées',
    statuses: {'cancelled'},
  ),
  OrderFilterOption(
    key: OrderFilterKey.history,
    label: 'Historique',
    statuses: orderHistoryStatuses,
  ),
];

List<OrderSection> sellerOrderSections(
  List<OrderModel> orders,
  OrderFilterKey filter, {
  required Set<int> hiddenIds,
}) {
  final visible = _filteredOrders(orders, filter, hiddenIds: hiddenIds);
  if (filter != OrderFilterKey.all) {
    return _singleSectionForFilter(visible, filter);
  }
  return _nonEmptySections([
    OrderSection(
      title: 'Nouvelles commandes',
      subtitle: 'À confirmer rapidement',
      orders: _statusOnly(visible, {'pending'}),
    ),
    OrderSection(
      title: 'En cours',
      subtitle: 'Confirmées, en préparation ou prêtes',
      orders: _statusOnly(visible, {
        'confirmed',
        'preparing',
        'ready_for_delivery',
      }),
    ),
    OrderSection(
      title: 'Historique',
      subtitle: 'Commandes livrées ou annulées',
      orders: _statusOnly(visible, orderHistoryStatuses),
    ),
  ]);
}

List<OrderSection> buyerOrderSections(
  List<OrderModel> orders,
  OrderFilterKey filter, {
  required Set<int> hiddenIds,
}) {
  final visible = _filteredOrders(orders, filter, hiddenIds: hiddenIds);
  if (filter != OrderFilterKey.all) {
    return _singleSectionForFilter(visible, filter);
  }
  return _nonEmptySections([
    OrderSection(
      title: 'Commandes actives',
      subtitle: 'À suivre jusqu’à la livraison',
      orders: _statusOnly(visible, orderActiveStatuses),
    ),
    OrderSection(
      title: 'Historique',
      subtitle: 'Commandes terminées ou annulées',
      orders: _statusOnly(visible, orderHistoryStatuses),
    ),
  ]);
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

OrderFilterOption orderFilterOption(OrderFilterKey key) {
  return orderFilterOptions.firstWhere((option) => option.key == key);
}

List<OrderModel> _filteredOrders(
  List<OrderModel> orders,
  OrderFilterKey filter, {
  required Set<int> hiddenIds,
}) {
  final option = orderFilterOption(filter);
  return orders
      .where((order) => !hiddenIds.contains(order.id))
      .where(
        (order) =>
            option.statuses.isEmpty || option.statuses.contains(order.status),
      )
      .toList(growable: false);
}

List<OrderSection> _singleSectionForFilter(
  List<OrderModel> orders,
  OrderFilterKey filter,
) {
  final option = orderFilterOption(filter);
  final title = switch (filter) {
    OrderFilterKey.history => 'Historique',
    OrderFilterKey.newOrders => 'Nouvelles commandes',
    OrderFilterKey.active => 'En cours',
    _ => option.label,
  };
  return [
    OrderSection(
      title: title,
      subtitle: '${orders.length} commande(s)',
      orders: orders,
    ),
  ];
}

List<OrderSection> _nonEmptySections(List<OrderSection> sections) {
  return sections
      .where((section) => section.orders.isNotEmpty)
      .toList(growable: false);
}

List<OrderModel> _statusOnly(List<OrderModel> orders, Set<String> statuses) {
  return orders
      .where((order) => statuses.contains(order.status))
      .toList(growable: false);
}
