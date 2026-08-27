import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';

class _RecordingApiClient extends ApiClient {
  String? lastPath;
  Map<String, String>? lastHeaders;
  Map<String, dynamic>? lastBody;
  Map<String, String>? lastQuery;

  @override
  Future<dynamic> postWithHeaders(
    String path, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    lastPath = path;
    lastHeaders = headers;
    lastBody = body;
    return _orderJson();
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = false,
  }) async {
    lastPath = path;
    lastQuery = queryParameters;
    if (path == ApiEndpoints.orderDetail(7)) return _orderJson();
    return {
      'success': true,
      'data': [_orderJson()],
      'meta': {'page': 1, 'page_size': 20, 'total': 1},
    };
  }

  @override
  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    lastPath = path;
    lastBody = body;
    return _orderJson(status: body?['status'] as String? ?? 'cancelled');
  }
}

Map<String, dynamic> _orderJson({String status = 'pending'}) => {
  'idorder': 7,
  'uuidorder': 'order-uuid',
  'total_amount': '25.00',
  'status': status,
  'payment_method': 'cash_on_delivery',
  'createdAt': '2026-08-25T12:00:00',
  'items': [
    {
      'product_idproduct': 3,
      'quantity': 2,
      'unit_price': '12.50',
      'total_price': '25.00',
    },
  ],
};

void main() {
  test(
    'create sends cash on delivery and the caller idempotency key',
    () async {
      final client = _RecordingApiClient();
      final service = OrderApiService(client: client);

      final order = await service.createOrder(
        items: const [OrderItemRequest(productId: 3, quantity: 2)],
        idempotencyKey: 'checkout-attempt-001',
      );

      expect(client.lastPath, ApiEndpoints.orders);
      expect(client.lastHeaders, {'Idempotency-Key': 'checkout-attempt-001'});
      expect(client.lastBody?['payment_method'], 'cash_on_delivery');
      expect(order.totalAmount, 25);
      expect(order.items.single.unitPrice, 12.5);
      expect(order.canBeCancelledByBuyer, isTrue);
    },
  );

  test('customer and store lists use their isolated endpoints', () async {
    final client = _RecordingApiClient();
    final service = OrderApiService(client: client);

    final customerOrders = await service.customerOrders(page: 2);
    expect(customerOrders, hasLength(1));
    expect(client.lastPath, ApiEndpoints.orders);
    expect(client.lastQuery?['page'], '2');

    final storeOrders = await service.storeOrders(storeId: 11);
    expect(storeOrders, hasLength(1));
    expect(client.lastPath, ApiEndpoints.storeOrders(11));
  });

  test('order detail uses the authenticated customer endpoint', () async {
    final client = _RecordingApiClient();
    final service = OrderApiService(client: client);

    final order = await service.orderDetail(7);

    expect(order.id, 7);
    expect(client.lastPath, ApiEndpoints.orderDetail(7));
  });

  test('cancel and seller status changes use patch endpoints', () async {
    final client = _RecordingApiClient();
    final service = OrderApiService(client: client);

    final cancelled = await service.cancelOrder(7);
    expect(cancelled.status, 'cancelled');
    expect(client.lastPath, ApiEndpoints.orderCancel(7));

    final confirmed = await service.updateStoreOrderStatus(
      storeId: 11,
      orderId: 7,
      status: 'confirmed',
    );
    expect(confirmed.status, 'confirmed');
    expect(client.lastPath, ApiEndpoints.storeOrderStatus(11, 7));
    expect(client.lastBody, {'status': 'confirmed'});
  });

  test('generated idempotency keys satisfy the API contract', () {
    final first = OrderApiService.newIdempotencyKey();
    final second = OrderApiService.newIdempotencyKey();

    expect(first.length, greaterThanOrEqualTo(8));
    expect(second, isNot(first));
  });
}
