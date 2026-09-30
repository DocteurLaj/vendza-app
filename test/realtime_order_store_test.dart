import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/notification/data/services/realtime_notification_service.dart';
import 'package:vendza/features/order/data/services/realtime_order_store.dart';

void main() {
  tearDown(() {
    liveOrderStore.value = const [];
  });

  test('live order events upsert and move open order lists immediately', () {
    final service = RealtimeNotificationService(
      baseUrl: 'https://api.test/api/v1',
    );

    const created = '''event: order_created
data: {"idorder": 7, "uuidorder": "order-uuid", "total_amount": "25.00", "status": "pending", "payment_method": "cash_on_delivery", "store_idstore": 11, "store_name": "Boutique test", "store_image": "https://cdn.vendza.test/store.png", "store_address": "Kinshasa", "contact_phone": "+243****0111", "delivery_address": "Avenue Commerce 12, Kinshasa", "customer_note": "Appelez-moi", "createdAt": "2026-08-25T12:00:00", "items": [{"product_idproduct": 3, "quantity": 2, "unit_price": "12.50", "total_price": "25.00", "product_name": "Produit test", "product_image": "https://cdn.vendza.test/product.png"}]}

''';
    const confirmed = '''event: order_status_updated
data: {"idorder": 7, "uuidorder": "order-uuid", "total_amount": "25.00", "status": "confirmed", "payment_method": "cash_on_delivery", "store_idstore": 11, "store_name": "Boutique test", "store_image": "https://cdn.vendza.test/store.png", "store_address": "Kinshasa", "contact_phone": "+243****0111", "delivery_address": "Avenue Commerce 12, Kinshasa", "customer_note": "Appelez-moi", "createdAt": "2026-08-25T12:00:00", "items": [{"product_idproduct": 3, "quantity": 2, "unit_price": "12.50", "total_price": "25.00", "product_name": "Produit test", "product_image": "https://cdn.vendza.test/product.png"}]}

''';

    service.handleSseChunkForTest(created);
    expect(liveOrderStore.value, hasLength(1));
    expect(liveOrdersForStore(11).single.status, 'pending');

    service.handleSseChunkForTest(confirmed);
    expect(liveOrderStore.value, hasLength(1));
    expect(liveOrdersForStore(11).single.status, 'confirmed');
  });
}
