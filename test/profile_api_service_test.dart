import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/features/profil/data/services/profile_api_service.dart';

class _FakeApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastBody;
  bool? lastAuthenticated;

  @override
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    lastPath = path;
    lastBody = body;
    lastAuthenticated = authenticated;
    return {
      'message': 'ok',
      'address': {'city': body?['new_city']},
    };
  }
}

void main() {
  test('updateAddress sends a simple optional address payload', () async {
    final client = _FakeApiClient();
    final service = ProfileApiService(client: client);

    await service.updateAddress(address: 'Kinshasa');

    expect(client.lastPath, ApiEndpoints.profileAddress);
    expect(client.lastAuthenticated, isTrue);
    expect(client.lastBody, {'new_city': 'Kinshasa'});
  });

  test('updateAddress can clear the profile address', () async {
    final client = _FakeApiClient();
    final service = ProfileApiService(client: client);

    await service.updateAddress(address: '   ');

    expect(client.lastBody, {'new_city': ''});
  });
}
