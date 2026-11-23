import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/presentation/pages/store_orders_page.dart';
import 'package:vendza/features/store/data/models/store_model.dart';

class _FakeOrdersApi extends OrderApiService {
  final updates = <String>[];
  final orders = <OrderModel>[
    _order(2481, 'pending', phone: '0812345678', address: 'Gombe, Kinshasa'),
    _order(2478, 'confirmed'),
    _order(2477, 'delivered'),
  ];

  @override
  Future<List<OrderModel>> storeOrders({
    required int storeId,
    int page = 1,
    int pageSize = 20,
  }) async => orders;

  @override
  Future<OrderModel> updateStoreOrderStatus({
    required int storeId,
    required int orderId,
    required String status,
  }) async {
    updates.add(status);
    final updated = _order(
      orderId,
      status,
      phone: '0812345678',
      address: 'Gombe, Kinshasa',
    );
    orders[orders.indexWhere((o) => o.id == orderId)] = updated;
    return updated;
  }
}

OrderModel _order(int id, String status, {String? phone, String? address}) =>
    OrderModel(
      id: id,
      uuid: 'order-$id',
      totalAmount: 48000,
      status: status,
      paymentMethod: 'cash_on_delivery',
      createdAt: DateTime(2026, 11, 12),
      storeId: 7,
      contactPhone: phone,
      deliveryAddress: address,
      items: const [
        OrderItemModel(
          productId: 1,
          productName: 'Lampe de bureau',
          quantity: 1,
          unitPrice: 48000,
          totalPrice: 48000,
        ),
      ],
    );

void main() {
  final store = ListStoreModel(
    id: '7',
    name: 'Maison Kivu',
    description: '',
    imageUrl: '',
    rating: 0,
  );
  late _FakeOrdersApi api;

  setUp(() => api = _FakeOrdersApi());

  Future<void> openPending(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StoreOrdersPage(store: store, apiService: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 commande à traiter'), findsOneWidget);
    expect(find.text('Commande #2481'), findsOneWidget);
    expect(find.text('Commande #2478'), findsNothing);
    await tester.tap(find.text('Examiner').first);
    await tester.pumpAndSettle();
  }

  testWidgets('pending queue opens inspectable detail before status action', (
    tester,
  ) async {
    await openPending(tester);
    expect(find.text('Lampe de bureau × 1'), findsOneWidget);
    expect(find.text('Gombe, Kinshasa'), findsOneWidget);
    expect(find.text('0812345678'), findsOneWidget);
    expect(find.text('Contacter le client'), findsOneWidget);
    expect(find.text('Confirmer la commande'), findsOneWidget);
    expect(api.updates, isEmpty);
    await tester.tap(find.text('Confirmer la commande'));
    await tester.pumpAndSettle();
    expect(api.updates, ['confirmed']);
    expect(find.text('Préparer la commande'), findsOneWidget);
  });

  testWidgets(
    'cancellation needs explicit confirmation and dismissal leaves order intact',
    (tester) async {
      await openPending(tester);
      await tester.ensureVisible(find.text('Annuler la commande'));
      await tester.tap(find.text('Annuler la commande'));
      await tester.pumpAndSettle();
      expect(api.updates, isEmpty);
      await tester.tap(find.text('Conserver la commande'));
      await tester.pumpAndSettle();
      expect(api.updates, isEmpty);
      await tester.tap(find.text('Annuler la commande'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer l’annulation'));
      await tester.pumpAndSettle();
      expect(api.updates, ['cancelled']);
    },
  );

  testWidgets('tabs keep active and history orders accessible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StoreOrdersPage(store: store, apiService: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('En cours'));
    await tester.pumpAndSettle();
    expect(find.text('Commande #2478'), findsOneWidget);
    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();
    expect(find.text('Commande #2477'), findsOneWidget);
  });
}
