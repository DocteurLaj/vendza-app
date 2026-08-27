import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';

class NotificationApiService {
  NotificationApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<Map<String, dynamic>> createNotification({
    required int userId,
    required String content,
    required String type,
  }) async {
    final response = await _client.post(
      ApiEndpoints.notificationAdd,
      body: {'user_iduser': userId, 'content': content, 'type': type},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> notificationsForCurrentUser() async {
    final response = await _client.get(
      ApiEndpoints.notificationsMe,
      authenticated: true,
    );
    return List<Map<String, dynamic>>.from(
      (response as List).map((item) => Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Map<String, dynamic>> markAsSeen(int notificationId) async {
    final response = await _client.put(
      ApiEndpoints.notificationSeen(notificationId),
      authenticated: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    final response = await _client.delete(
      ApiEndpoints.notificationDelete(notificationId),
      authenticated: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
