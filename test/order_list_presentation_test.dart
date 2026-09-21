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

    test('exposes only three simple primary tabs per role', () {
      expect(sellerOrderSegmentOptions.map((segment) => segment.label), [
        'À traiter',
        'En cours',
        'Historique',
      ]);
      expect(buyerOrderSegmentOptions.map((segment) => segment.label), [
        'En cours',
        'Terminées',
        'Annulées',
      ]);
    });

    test('moves seller orders into the selected simple segment', () {
      expect(
        sellerOrdersForSegment(
          orders,
          OrderSegmentKey.toProcess,
          hiddenIds: {},
        ).map((order) => order.id),
        [1],
      );
      expect(
        sellerOrdersForSegment(
          orders,
          OrderSegmentKey.active,
          hiddenIds: {},
        ).map((order) => order.id),
        [2, 3, 4],
      );
      expect(
        sellerOrdersForSegment(
          orders,
          OrderSegmentKey.history,
          hiddenIds: {5},
        ).map((order) => order.id),
        [6],
      );
    });

    test(
      'moves buyer orders into active, completed, and cancelled segments',
      () {
        expect(
          buyerOrdersForSegment(
            orders,
            OrderSegmentKey.active,
            hiddenIds: {},
          ).map((order) => order.id),
          [1, 2, 3, 4],
        );
        expect(
          buyerOrdersForSegment(
            orders,
            OrderSegmentKey.completed,
            hiddenIds: {},
          ).map((order) => order.id),
          [5],
        );
        expect(
          buyerOrdersForSegment(
            orders,
            OrderSegmentKey.cancelled,
            hiddenIds: {},
          ).map((order) => order.id),
          [6],
        );
      },
    );

    test('keeps detailed status choices as advanced filters only', () {
      expect(orderAdvancedFilterOptions.map((option) => option.label), [
        'Tous les statuts',
        'Commande reçue',
        'Confirmée',
        'En préparation',
        'Prête',
        'Livrée',
        'Annulée',
      ]);
      expect(
        applyAdvancedOrderFilter(
          orders,
          OrderFilterKey.preparing,
          hiddenIds: {},
        ).map((order) => order.id),
        [3],
      );
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
