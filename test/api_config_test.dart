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
}
