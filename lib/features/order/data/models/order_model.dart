class OrderItemRequest {
  const OrderItemRequest({required this.productId, required this.quantity});

  final int productId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'product_idproduct': productId,
    'quantity': quantity,
  };
}

class OrderItemModel {
  const OrderItemModel({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['product_idproduct'] as int,
      quantity: json['quantity'] as int,
      unitPrice: _asDouble(json['unit_price']),
      totalPrice: _asDouble(json['total_price']),
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.uuid,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String uuid;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  bool get canBeCancelledByBuyer => status == 'pending';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['idorder'] as int,
      uuid: json['uuidorder'] as String,
      totalAmount: _asDouble(json['total_amount']),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map(
            (item) =>
                OrderItemModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
    );
  }
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.parse(value as String);
}
