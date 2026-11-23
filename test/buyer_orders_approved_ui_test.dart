import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';

class OrdersApiFixture extends OrderApiService {
  OrdersApiFixture(this.orders);
  final List<OrderModel> orders;
  int detailCalls = 0;
  @override
  Future<List<OrderModel>> customerOrders({
    int page = 1,
    int pageSize = 20,
  }) async => orders;
  @override
  Future<OrderModel> orderDetail(int orderId) async {
    detailCalls++;
    return orders.singleWhere((order) => order.id == orderId);
  }
}

OrderModel sample(int id, String status, {String? address}) => OrderModel(
  id: id,
  uuid: '$id',
  totalAmount: 48000,
  status: status,
  paymentMethod: 'cash',
  createdAt: DateTime(2026, 11, 12),
  storeName: 'Maison Kivu',
  deliveryAddress: address,
  items: const [
    OrderItemModel(
      productId: 1,
      quantity: 1,
      unitPrice: 48000,
      totalPrice: 48000,
      productName: 'Lampe de bureau',
    ),
  ],
);

void main() {
  testWidgets('active focus card and real detail navigation', (tester) async {
    final api = OrdersApiFixture([
      sample(2481, 'preparing', address: 'Gombe, Kinshasa'),
      sample(2476, 'pending'),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: BuyerOrdersPage(inNavigation: true, api: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vos achats, en un coup d’œil'), findsOneWidget);
    expect(find.text('Autres achats'), findsOneWidget);
    expect(find.text('Voir le détail de la commande'), findsOneWidget);
    await tester.tap(find.text('Voir le détail de la commande'));
    await tester.pumpAndSettle();
    expect(api.detailCalls, 1);
    expect(find.text('Commande #2481'), findsOneWidget);
    expect(find.text('Étape actuelle'), findsOneWidget);
    expect(find.text('Gombe, Kinshasa'), findsOneWidget);
    expect(find.textContaining('GPS'), findsNothing);
  });

  testWidgets('segments and status filter show only matching real orders', (
    tester,
  ) async {
    final api = OrdersApiFixture([
      sample(11, 'preparing'),
      sample(12, 'pending'),
      sample(13, 'delivered'),
      sample(14, 'cancelled'),
    ]);
    await tester.pumpWidget(
      MaterialApp(home: BuyerOrdersPage(inNavigation: true, api: api)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('#11'), findsWidgets);
    await tester.tap(find.text('Terminées'));
    await tester.pumpAndSettle();
    expect(find.textContaining('#13'), findsWidgets);
    expect(find.textContaining('#11'), findsNothing);
    await tester.tap(find.byTooltip('Filtrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commande reçue').last);
    await tester.pumpAndSettle();
    expect(find.text('Aucune commande ici'), findsOneWidget);
    await tester.tap(find.byTooltip('Filtrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tous les statuts').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('#13'), findsWidgets);
  });

  testWidgets('compact phone exposes detail and back without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = OrdersApiFixture([sample(11, 'pending')]);
    await tester.pumpWidget(
      MaterialApp(home: BuyerOrdersPage(inNavigation: true, api: api)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Voir le détail de la commande'));
    await tester.tap(find.text('Voir le détail de la commande'));
    await tester.pumpAndSettle();
    expect(find.text('Adresse non renseignée'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Mes commandes'), findsOneWidget);
  });

  testWidgets('archived order can still be hidden from buyer history', (
    tester,
  ) async {
    final api = OrdersApiFixture([sample(13, 'delivered')]);
    await tester.pumpWidget(
      MaterialApp(home: BuyerOrdersPage(inNavigation: true, api: api)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminées'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir le détail de la commande'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Autres options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masquer de l’historique'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune commande ici'), findsOneWidget);
  });
}
