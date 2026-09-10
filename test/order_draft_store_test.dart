import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/order/data/services/order_draft_store.dart';
import 'package:vendza/shared/models/product_model.dart';

ProductModel product({
  required String id,
  required String storeId,
  String storeName = 'Store',
  String name = 'Product',
  String price = '12.50',
}) {
  return ProductModel(
    id: id,
    name: name,
    price: price,
    imageurl: '',
    status: 'in_stock',
    storeId: storeId,
    storeName: storeName,
  );
}

void main() {
  test(
    'draft groups multiple products from the same store with quantities',
    () {
      final draft = OrderDraftStore();

      draft.addProduct(product(id: '3', storeId: '11', name: 'A'), quantity: 2);
      draft.addProduct(product(id: '4', storeId: '11', name: 'B'));
      draft.increment('3');

      expect(draft.value?.storeId, '11');
      expect(draft.value?.items, hasLength(2));
      expect(draft.value?.items.first.quantity, 3);
      expect(draft.value?.totalItems, 4);
      expect(draft.value?.totalAmount, 50.0);
    },
  );

  test(
    'switching store replaces the draft so a command targets one boutique',
    () {
      final draft = OrderDraftStore();

      draft.addProduct(product(id: '3', storeId: '11'));
      draft.addProduct(product(id: '8', storeId: '22', storeName: 'Other'));

      expect(draft.value?.storeId, '22');
      expect(draft.value?.storeName, 'Other');
      expect(draft.value?.items, hasLength(1));
      expect(draft.value?.items.single.productId, 8);
    },
  );

  test('checkout validation requires phone and delivery address', () {
    final draft = OrderDraftStore();
    draft.addProduct(product(id: '3', storeId: '11'));

    expect(
      draft.validateCheckout(contactPhone: '', deliveryAddress: 'Kin'),
      'Le numéro de téléphone est obligatoire.',
    );
    expect(
      draft.validateCheckout(
        contactPhone: '+243999000111',
        deliveryAddress: '',
      ),
      'L’adresse de livraison est obligatoire.',
    );
    expect(
      draft.validateCheckout(
        contactPhone: '+243999000111',
        deliveryAddress: 'Kin',
      ),
      isNull,
    );
  });
}
