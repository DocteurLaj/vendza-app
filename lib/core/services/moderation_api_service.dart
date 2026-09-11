import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';

class ModerationApiService {
  ModerationApiService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<void> requestReview({
    required String targetType,
    required String targetId,
    required String message,
  }) async {
    await _client.post(
      ApiEndpoints.reports,
      authenticated: true,
      body: {
        'target_type': targetType,
        'target_id': targetId,
        'reason': 'Demande de révision',
        'details': message.trim(),
      },
    );
  }
}
