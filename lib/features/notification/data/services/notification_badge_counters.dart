import 'package:vendza/features/notification/data/models/notification_model.dart';

class NotificationBadgeCounters {
  const NotificationBadgeCounters({
    required this.store,
    required this.chat,
    required this.orders,
    required this.storeOrders,
    required this.storeAttention,
  });

  final int store;
  final int chat;
  final int orders;
  final Map<String, int> storeOrders;
  final Map<String, int> storeAttention;

  int get storeNav => store + orders;

  int storeOrdersFor(String storeId) => storeOrders[storeId] ?? 0;
  int storeAttentionFor(String storeId) => storeAttention[storeId] ?? 0;
}

NotificationBadgeCounters notificationBadgeCounters(
  List<NotificationModel> notifications,
) {
  var store = 0;
  var chat = 0;
  var orders = 0;
  final storeOrders = <String, int>{};
  final storeAttention = <String, int>{};

  for (final notification in notifications) {
    if (notification.isRead) continue;
    if (isOrderAttentionNotification(notification)) {
      orders++;
      final storeId = notification.storeId?.toString();
      if (storeId != null && storeId.isNotEmpty) {
        storeOrders[storeId] = (storeOrders[storeId] ?? 0) + 1;
      }
      continue;
    }
    if (isStoreAttentionNotification(notification)) {
      store++;
      final storeId = notification.storeId?.toString();
      if (storeId != null && storeId.isNotEmpty) {
        storeAttention[storeId] = (storeAttention[storeId] ?? 0) + 1;
      }
      continue;
    }
    if (isChatAttentionNotification(notification)) {
      chat++;
    }
  }

  return NotificationBadgeCounters(
    store: store,
    chat: chat,
    orders: orders,
    storeOrders: Map.unmodifiable(storeOrders),
    storeAttention: Map.unmodifiable(storeAttention),
  );
}

bool isOrderAttentionNotification(NotificationModel notification) {
  final name = notification.name.trim().toLowerCase();
  final threadType = notification.threadType?.trim().toLowerCase() ?? '';
  final threadId = notification.threadId?.trim().toLowerCase() ?? '';
  return notification.orderId != null ||
      name == 'store_order' ||
      name == 'order' ||
      name.contains('order') ||
      name.contains('commande') ||
      threadType == 'order' ||
      threadId.startsWith('order:');
}

bool isStoreAttentionNotification(NotificationModel notification) {
  final name = notification.name.trim().toLowerCase();
  final threadType = notification.threadType?.trim().toLowerCase() ?? '';
  final threadId = notification.threadId?.trim().toLowerCase() ?? '';
  return notification.storeId != null ||
      isProductStockAttentionNotification(notification) ||
      name.contains('store') ||
      name.contains('boutique') ||
      threadType == 'store' ||
      threadId.startsWith('store:');
}

bool isProductStockAttentionNotification(NotificationModel notification) {
  final name = notification.name.trim().toLowerCase();
  final threadType = notification.threadType?.trim().toLowerCase() ?? '';
  final threadId = notification.threadId?.trim().toLowerCase() ?? '';
  return name == 'product_low_stock' ||
      name == 'product_out_of_stock' ||
      threadType == 'product' ||
      threadId.startsWith('product:');
}

bool isChatAttentionNotification(NotificationModel notification) {
  return !isOrderAttentionNotification(notification) &&
      !isStoreAttentionNotification(notification);
}
