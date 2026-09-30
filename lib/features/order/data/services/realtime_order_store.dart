import 'package:flutter/foundation.dart';
import 'package:vendza/features/order/data/models/order_model.dart';

final ValueNotifier<List<OrderModel>> liveOrderStore =
    ValueNotifier<List<OrderModel>>(const []);

void replaceLiveOrders(List<OrderModel> orders) {
  liveOrderStore.value = List<OrderModel>.from(orders);
}

void replaceLiveOrdersForStore(int storeId, List<OrderModel> orders) {
  final scopedIds = orders.map((order) => order.id).toSet();
  final retained = liveOrderStore.value.where((order) {
    if (order.storeId != storeId) return true;
    return !scopedIds.contains(order.id);
  }).toList();
  liveOrderStore.value = [...orders, ...retained];
}

void upsertLiveOrder(OrderModel order) {
  final existing = liveOrderStore.value;
  if (existing.any((item) => item.id == order.id)) {
    liveOrderStore.value = existing
        .map((item) => item.id == order.id ? order : item)
        .toList(growable: false);
  } else {
    liveOrderStore.value = [order, ...existing];
  }
}

List<OrderModel> liveOrdersForStore(int storeId) {
  return liveOrderStore.value
      .where((order) => order.storeId == storeId)
      .toList(growable: false);
}
