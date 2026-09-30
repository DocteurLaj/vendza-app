import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/presentation/helpers/order_list_presentation.dart';

OrderModel _order(int id, String status, {int? storeId}) => OrderModel(
  id: id,
  uuid: 'order-$id',
  totalAmount: id * 10,
  status: status,
  paymentMethod: 'cash_on_delivery',
  storeId: storeId,
  createdAt: DateTime(2026, 9, id),
  items: const [
    OrderItemModel(productId: 1, quantity: 1, unitPrice: 10, totalPrice: 10),
  ],
);

void main() {
  test('buyer copy focuses on essential tracking instead of cockpit metrics', () {
    final summary = summarizeOrders([
      _order(1, 'pending'),
      _order(2, 'delivered'),
      _order(3, 'cancelled'),
    ], hiddenIds: {});

    expect(
      buyerOrdersIntro(summary),
      'Suivez uniquement vos commandes en cours. Les commandes livrées ou annulées restent accessibles dans les filtres.',
    );
    expect(visibleOrderMetricLabels(role: OrderListRole.buyer), isEmpty);
  });

  test('seller copy focuses on treating orders and contact clarity', () {
    final summary = summarizeOrders([
      _order(1, 'pending'),
      _order(2, 'confirmed'),
      _order(3, 'delivered'),
    ], hiddenIds: {});

    expect(
      sellerOrdersIntro(summary),
      'Priorité aux commandes à traiter. Les contacts client et la prochaine action restent visibles dans chaque commande.',
    );
    expect(visibleOrderMetricLabels(role: OrderListRole.seller), isEmpty);
  });

  test('active order attention is scoped per store', () {
    final counts = activeOrderAttentionByStore([
      _order(1, 'pending', storeId: 7),
      _order(2, 'confirmed', storeId: 7),
      _order(3, 'delivered', storeId: 7),
      _order(4, 'cancelled', storeId: 8),
      _order(5, 'preparing', storeId: 9),
    ]);

    expect(counts, {7: 2, 9: 1});
  });
}
