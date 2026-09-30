import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_badge_counters.dart';

NotificationModel notif({
  required String id,
  required String name,
  bool read = false,
  int? storeId,
  int? orderId,
  String? threadId,
  String? threadType,
}) {
  return NotificationModel(
    id: id,
    name: name,
    description: 'Notification $id',
    imageUrl: '',
    isRead: read,
    storeId: storeId,
    orderId: orderId,
    threadId: threadId,
    threadType: threadType,
  );
}

void main() {
  test(
    'badge counters route unread notifications to store chat and orders',
    () {
      final counters = notificationBadgeCounters([
        notif(id: '1', name: 'store_update', storeId: 7),
        notif(id: '2', name: 'message', threadType: 'chat'),
        notif(id: '3', name: 'store_order', storeId: 7, orderId: 44),
        notif(id: '4', name: 'order', orderId: 45),
        notif(id: '5', name: 'message', threadType: 'chat', read: true),
        notif(id: '6', name: 'product_low_stock', storeId: 7),
      ]);

      expect(counters.store, 2);
      expect(counters.chat, 1);
      expect(counters.orders, 2);
      expect(counters.storeOrdersFor('7'), 1);
      expect(counters.storeAttentionFor('7'), 2);
    },
  );

  test(
    'badge counters ignore read notifications and do not leave stale badges',
    () {
      final unread = notif(
        id: '1',
        name: 'store_order',
        storeId: 7,
        orderId: 44,
      );
      expect(notificationBadgeCounters([unread]).orders, 1);

      final read = unread.copyWith(isRead: true);
      final counters = notificationBadgeCounters([read]);

      expect(counters.store, 0);
      expect(counters.chat, 0);
      expect(counters.orders, 0);
      expect(counters.storeOrdersFor('7'), 0);
    },
  );
}
