import 'dart:convert';
import 'dart:math';

import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/features/order/data/models/order_model.dart';

class OrderApiService {
  OrderApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  static String newIdempotencyKey() {
    final bytes = List<int>.generate(18, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<OrderModel> createOrder({
    required List<OrderItemRequest> items,
    required String idempotencyKey,
  }) async {
    final response = await _client.postWithHeaders(
      ApiEndpoints.orders,
      authenticated: true,
      headers: {'Idempotency-Key': idempotencyKey},
      body: {
        'payment_method': 'cash_on_delivery',
        'items': items.map((item) => item.toJson()).toList(growable: false),
      },
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<List<OrderModel>> customerOrders({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.orders,
      authenticated: true,
      queryParameters: {'page': '$page', 'page_size': '$pageSize'},
    );
    return _ordersFromResponse(response);
  }

  Future<OrderModel> orderDetail(int orderId) async {
    final response = await _client.get(
      ApiEndpoints.orderDetail(orderId),
      authenticated: true,
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<List<OrderModel>> storeOrders({
    required int storeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.storeOrders(storeId),
      authenticated: true,
      queryParameters: {'page': '$page', 'page_size': '$pageSize'},
    );
    return _ordersFromResponse(response);
  }

  Future<OrderModel> cancelOrder(int orderId) async {
    final response = await _client.patch(
      ApiEndpoints.orderCancel(orderId),
      authenticated: true,
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<OrderModel> updateStoreOrderStatus({
    required int storeId,
    required int orderId,
    required String status,
  }) async {
    final response = await _client.patch(
      ApiEndpoints.storeOrderStatus(storeId, orderId),
      authenticated: true,
      body: {'status': status},
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  List<OrderModel> _ordersFromResponse(dynamic response) {
    return unwrapApiList(
      response,
    ).map(OrderModel.fromJson).toList(growable: false);
  }
}
