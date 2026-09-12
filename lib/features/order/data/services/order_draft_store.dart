import 'package:flutter/foundation.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/shared/models/product_model.dart';

class OrderDraftItem {
  const OrderDraftItem({required this.product, required this.quantity});

  final ProductModel product;
  final int quantity;

  int get productId => int.tryParse(product.id) ?? 0;
  double get unitPrice => double.tryParse(product.price.trim()) ?? 0;
  double get totalPrice => unitPrice * quantity;

  OrderDraftItem copyWith({int? quantity}) {
    return OrderDraftItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  OrderItemRequest toRequest() {
    return OrderItemRequest(productId: productId, quantity: quantity);
  }
}

class OrderDraft {
  const OrderDraft({
    required this.storeId,
    required this.storeName,
    required this.items,
  });

  final String storeId;
  final String storeName;
  final List<OrderDraftItem> items;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  OrderDraft copyWith({List<OrderDraftItem>? items}) {
    return OrderDraft(
      storeId: storeId,
      storeName: storeName,
      items: items ?? this.items,
    );
  }
}

class OrderDraftStore extends ChangeNotifier {
  OrderDraft? _value;

  OrderDraft? get value => _value;

  void addProduct(ProductModel product, {int quantity = 1}) {
    final storeId = product.storeId.trim();
    final safeQuantity = quantity < 1 ? 1 : quantity;
    final current = _value;
    if (current == null || current.storeId != storeId) {
      _value = OrderDraft(
        storeId: storeId,
        storeName: product.storeName.trim().isNotEmpty
            ? product.storeName.trim()
            : 'Boutique',
        items: [OrderDraftItem(product: product, quantity: safeQuantity)],
      );
      notifyListeners();
      return;
    }

    final items = List<OrderDraftItem>.from(current.items);
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      items.add(OrderDraftItem(product: product, quantity: safeQuantity));
    } else {
      items[index] = items[index].copyWith(
        quantity: items[index].quantity + safeQuantity,
      );
    }
    _value = current.copyWith(items: items);
    notifyListeners();
  }

  void increment(String productId) => _changeQuantity(productId, 1);

  void decrement(String productId) => _changeQuantity(productId, -1);

  void remove(String productId) {
    final current = _value;
    if (current == null) return;
    final items = current.items
        .where((item) => item.product.id != productId)
        .toList(growable: false);
    _value = items.isEmpty ? null : current.copyWith(items: items);
    notifyListeners();
  }

  void clear() {
    _value = null;
    notifyListeners();
  }

  String? validateCheckout({
    required String contactPhone,
    required String deliveryAddress,
  }) {
    final current = _value;
    if (current == null || current.items.isEmpty) {
      return 'Choisissez au moins un produit.';
    }
    if (current.items.any((item) => item.productId <= 0 || item.quantity < 1)) {
      return 'Un produit de la commande est invalide.';
    }
    if (contactPhone.trim().isEmpty) {
      return 'Le numéro de téléphone est obligatoire.';
    }
    if (deliveryAddress.trim().isEmpty) {
      return 'L’adresse de livraison est obligatoire.';
    }
    return null;
  }

  void _changeQuantity(String productId, int delta) {
    final current = _value;
    if (current == null) return;
    final items = <OrderDraftItem>[];
    for (final item in current.items) {
      if (item.product.id != productId) {
        items.add(item);
        continue;
      }
      final next = item.quantity + delta;
      if (next > 0) items.add(item.copyWith(quantity: next));
    }
    _value = items.isEmpty ? null : current.copyWith(items: items);
    notifyListeners();
  }
}

final orderDraftStore = OrderDraftStore();
