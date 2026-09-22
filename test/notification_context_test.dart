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
      'title': 'Commande chez Boutique',
      'image_url': 'https://cdn.vendza.test/store.png',
      'store_name': 'Boutique test',
      'store_image': 'https://cdn.vendza.test/store.png',
      'product_idproduct': 3,
      'product_name': 'Produit test',
      'product_image': 'https://cdn.vendza.test/product.png',
      'thread_id': 'order:44',
      'thread_type': 'order',
      'createdAt': '2026-09-10T14:32:00',
      'seen': false,
      'store_idstore': 7,
      'order_idorder': 44,
    });

    expect(notification.id, '12');
    expect(notification.name, 'store_order');
    expect(notification.storeId, 7);
    expect(notification.orderId, 44);
    expect(notification.threadId, 'order:44');
    expect(notification.storeName, 'Boutique test');
    expect(notification.productName, 'Produit test');
    expect(notification.imageUrl, 'https://cdn.vendza.test/store.png');
    expect(notification.createdAt, DateTime(2026, 9, 10, 14, 32));
    expect(notification.isRead, isFalse);
  });

  test('notifications group as chat threads newest first', () {
    final threads = groupNotificationThreads([
      NotificationModel(
        id: '1',
        name: 'general',
        description: 'Ancien',
        imageUrl: '',
        isRead: true,
        threadId: 'general',
        createdAt: DateTime(2026, 9, 10, 10),
      ),
      NotificationModel(
        id: '2',
        name: 'store_order',
        description: 'Nouveau',
        imageUrl: 'store.png',
        isRead: false,
        storeName: 'Boutique',
        threadId: 'store:7',
        createdAt: DateTime(2026, 9, 10, 12),
      ),
      NotificationModel(
        id: '3',
        name: 'store_order',
        description: 'Suite',
        imageUrl: 'store.png',
        isRead: false,
        threadId: 'store:7',
        createdAt: DateTime(2026, 9, 10, 13),
      ),
    ]);

    expect(threads.first.id, 'store:7');
    expect(threads.first.title, 'Boutique');
    expect(threads.first.messageCount, 2);
    expect(threads.first.unreadCount, 2);
    expect(threads.last.id, 'general');
  });

  test(
    'store chat keeps boutique identity even when latest message has no store name',
    () {
      final threads = groupNotificationThreads([
        NotificationModel(
          id: '1',
          name: 'store_order',
          title: 'Commande',
          description: 'Première commande',
          imageUrl: '',
          isRead: true,
          storeId: 9,
          storeName: 'Maison Laj',
          storeImage: 'store.png',
          threadId: 'store:9',
          createdAt: DateTime(2026, 9, 10, 10),
        ),
        NotificationModel(
          id: '2',
          name: 'store_order',
          title: 'Commande livrée',
          description: 'Dernière mise à jour',
          imageUrl: '',
          isRead: false,
          storeId: 9,
          threadId: 'store:9',
          createdAt: DateTime(2026, 9, 10, 12),
        ),
      ]);

      expect(threads.single.title, 'Maison Laj');
      expect(threads.single.imageUrl, 'store.png');
      expect(threads.single.unreadCount, 1);
    },
  );

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
