import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_config.dart';

void main() {
  test('debug default base URL targets the Android emulator loopback', () {
    // In test/debug builds without dart-define, LAN/emulator HTTP is allowed.
    expect(ApiConfig.defaultBaseUrl, contains('10.0.2.2'));
    expect(() => ApiConfig.validateForCurrentBuild(), returnsNormally);
  });

  test('rewrites localhost MinIO URLs toward the debug API host', () {
    final rewritten = ApiConfig.rewriteMediaUrl(
      'http://localhost:9000/vendza-images/users/x/avatar/y.jpg',
    );
    expect(rewritten, startsWith('http://10.0.2.2:9000/'));
  });

  test('normalizes API host URL to the v1 API prefix', () {
    expect(
      ApiConfig.normalizeBaseUrl('https://api.example.com'),
      'https://api.example.com/api/v1',
    );
  });

  test('keeps an existing v1 API prefix without a trailing slash', () {
    expect(
      ApiConfig.normalizeBaseUrl('https://api.example.com/api/v1/'),
      'https://api.example.com/api/v1',
    );
  });

  test('keeps deeper API URLs unchanged', () {
    expect(
      ApiConfig.normalizeBaseUrl('https://api.example.com/proxy/api/v1'),
      'https://api.example.com/proxy/api/v1',
    );
  });
}
