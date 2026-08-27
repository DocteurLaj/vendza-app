import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/deep_link/deep_link_service.dart';

void main() {
  final service = DeepLinkService.instance;

  test('parseDeepLink product via custom scheme', () {
    final target = service.parseDeepLink(Uri.parse('vendza://p/1'));
    expect(target, isA<ProductDeepLink>());
    expect((target as ProductDeepLink).id, '1');
  });

  test('parseDeepLink store via custom scheme', () {
    final target = service.parseDeepLink(Uri.parse('vendza://store/2'));
    expect(target, isA<StoreDeepLink>());
    expect((target as StoreDeepLink).id, '2');
  });

  test('parseDeepLink product via https', () {
    final target = service.parseDeepLink(Uri.parse('https://vendza.app/p/3'));
    expect(target, isA<ProductDeepLink>());
    expect((target as ProductDeepLink).id, '3');
  });

  test('parseDeepLink store via https', () {
    final target = service.parseDeepLink(
      Uri.parse('https://vendza.app/store/4'),
    );
    expect(target, isA<StoreDeepLink>());
    expect((target as StoreDeepLink).id, '4');
  });

  test('parseDeepLink password reset via custom scheme', () {
    final target = service.parseDeepLink(
      Uri.parse('vendza://reset-password?token=secure-token'),
    );
    expect(target, isA<ResetPasswordDeepLink>());
    expect((target as ResetPasswordDeepLink).token, 'secure-token');
  });

  test('parseDeepLink password reset via https', () {
    final target = service.parseDeepLink(
      Uri.parse('https://vendza.app/reset-password?token=secure-token'),
    );
    expect(target, isA<ResetPasswordDeepLink>());
    expect((target as ResetPasswordDeepLink).token, 'secure-token');
  });

  test('parseDeepLink returns null for unknown uri', () {
    expect(service.parseDeepLink(Uri.parse('https://example.com')), isNull);
  });
}
