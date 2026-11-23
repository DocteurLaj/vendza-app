import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/features/notification/data/services/notification_api_service.dart';

class _RecordingClient extends ApiClient {
  String? path;
  bool? authenticatedRequest;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    bool authenticated = false,
  }) async {
    this.path = path;
    authenticatedRequest = authenticated;
    return [
      {'idnotification': 4, 'thread_id': 'order:7', 'content': 'Confirmation'},
    ];
  }
}

void main() {
  test(
    'full notification history uses the authenticated thread route',
    () async {
      final client = _RecordingClient();
      final result = await NotificationApiService(
        client: client,
      ).notificationsForThread('order:7');
      expect(client.path, '/notification/threads/order%3A7');
      expect(client.authenticatedRequest, isTrue);
      expect(result.single['content'], 'Confirmation');
    },
  );
}
