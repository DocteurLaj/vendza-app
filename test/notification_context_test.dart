import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';

void main() {
  test('notification mapper keeps order and store context', () {
    final notification = notificationFromApi({
      'idnotification': 12,
      'type': 'store_order',
      'content': 'Nouvelle commande',
      'seen': false,
      'store_idstore': 7,
      'order_idorder': 44,
    });

    expect(notification.id, '12');
    expect(notification.name, 'store_order');
    expect(notification.storeId, 7);
    expect(notification.orderId, 44);
    expect(notification.isRead, isFalse);
  });

  test('markNotificationAsRead preserves navigation context', () async {
    notificationStore.value = [
      NotificationModel(
        id: '12',
        name: 'store_order',
        description: 'Nouvelle commande',
        imageUrl: '',
        isRead: false,
        storeId: 7,
        orderId: 44,
      ),
    ];

    await markNotificationAsRead('12');

    final notification = notificationStore.value.single;
    expect(notification.isRead, isTrue);
    expect(notification.storeId, 7);
    expect(notification.orderId, 44);
  });
}
