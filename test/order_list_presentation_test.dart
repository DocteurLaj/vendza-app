import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/presentation/helpers/order_list_presentation.dart';

OrderModel _order(int id, String status) => OrderModel(
  id: id,
  uuid: 'order-$id',
  totalAmount: id * 10,
  status: status,
  paymentMethod: 'cash_on_delivery',
  createdAt: DateTime(2026, 9, id),
  items: const [
    OrderItemModel(productId: 1, quantity: 1, unitPrice: 10, totalPrice: 10),
  ],
);

void main() {
  group('order list presentation', () {
    final orders = [
      _order(1, 'pending'),
      _order(2, 'confirmed'),
      _order(3, 'preparing'),
      _order(4, 'ready_for_delivery'),
      _order(5, 'delivered'),
      _order(6, 'cancelled'),
    ];

    test('moves orders into seller sections by status', () {
      final sections = sellerOrderSections(
        orders,
        OrderFilterKey.all,
        hiddenIds: {},
      );

      expect(sections.map((section) => section.title), [
        'Nouvelles commandes',
        'En cours',
        'Historique',
      ]);
      expect(sections[0].orders.map((order) => order.id), [1]);
      expect(sections[1].orders.map((order) => order.id), [2, 3, 4]);
      expect(sections[2].orders.map((order) => order.id), [5, 6]);
    });

    test('moves orders into buyer active/history sections by status', () {
      final sections = buyerOrderSections(
        orders,
        OrderFilterKey.all,
        hiddenIds: {},
      );

      expect(sections.map((section) => section.title), [
        'Commandes actives',
        'Historique',
      ]);
      expect(sections[0].orders.map((order) => order.id), [1, 2, 3, 4]);
      expect(sections[1].orders.map((order) => order.id), [5, 6]);
    });

    test('filters by status and hides locally deleted orders', () {
      final sections = sellerOrderSections(
        orders,
        OrderFilterKey.history,
        hiddenIds: {5},
      );

      expect(sections, hasLength(1));
      expect(sections.single.title, 'Historique');
      expect(sections.single.orders.map((order) => order.id), [6]);

      final preparing = buyerOrderSections(
        orders,
        OrderFilterKey.preparing,
        hiddenIds: {},
      );
      expect(preparing.single.orders.map((order) => order.id), [3]);
    });

    test('keeps active and history counts available for summary chips', () {
      final summary = summarizeOrders(orders, hiddenIds: {6});

      expect(summary.total, 5);
      expect(summary.newCount, 1);
      expect(summary.activeCount, 4);
      expect(summary.historyCount, 1);
      expect(summary.byStatus['delivered'], 1);
      expect(summary.byStatus['cancelled'], 0);
    });
  });
}
