import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/features/notification/data/services/realtime_notification_service.dart';
import 'package:vendza/features/notification/data/services/sse_parser.dart';

void main() {
  tearDown(() {
    notificationStore.value = const [];
  });

  test('SSE parser decodes notification events and ignores heartbeats', () {
    final messages = parseSseMessages('''
: keep-alive

event: notification
data: {"idnotification": 9, "type": "store_order", "content": "Nouvelle commande", "seen": false, "user_iduser": 2, "createdAt": "2026-09-30T10:00:00"}

''');

    expect(messages, hasLength(1));
    expect(messages.single.event, 'notification');
    expect(messages.single.data['idnotification'], 9);
  });

  test(
    'realtime notification service prepends live notifications and dedupes',
    () {
      final service = RealtimeNotificationService(
        baseUrl: 'https://api.test/api/v1',
      );
      const chunk = '''event: notification
data: {"idnotification": 9, "type": "store_order", "content": "Nouvelle commande", "seen": false, "user_iduser": 2, "store_idstore": 7, "order_idorder": 44, "createdAt": "2026-09-30T10:00:00"}

''';

      service.handleSseChunkForTest(chunk);
      service.handleSseChunkForTest(chunk);

      expect(notificationStore.value, hasLength(1));
      expect(notificationStore.value.single.id, '9');
      expect(notificationStore.value.single.storeId, 7);
      expect(notificationStore.value.single.orderId, 44);
      expect(notificationStore.value.single.isRead, isFalse);
    },
  );
}
