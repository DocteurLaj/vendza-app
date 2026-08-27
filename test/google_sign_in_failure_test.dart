import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vendza/features/auth/data/services/google_sign_in_failure.dart';

void main() {
  test('empty canceled is treated as silent dismiss', () {
    final mapped = GoogleSignInFailureMapper.map(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );
    expect(mapped, isNull);
  });

  test('canceled with config-like description becomes actionable error', () {
    final mapped = GoogleSignInFailureMapper.map(
      const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'OAuth client configuration error',
      ),
    );
    expect(mapped, isNotNull);
    expect(mapped!.message, contains('Config Google incomplète'));
    expect(mapped.message, contains('OAuth client configuration error'));
  });

  test('clientConfigurationError always surfaces config hint', () {
    final mapped = GoogleSignInFailureMapper.map(
      const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
      ),
    );
    expect(mapped, isNotNull);
    expect(mapped!.message, contains('app.vendza.marketplace'));
  });

  test('looksLikeConfigurationCancel detects common keywords', () {
    expect(
      GoogleSignInFailureMapper.looksLikeConfigurationCancel(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'Missing SHA-1 fingerprint',
        ),
      ),
      isTrue,
    );
    expect(
      GoogleSignInFailureMapper.looksLikeConfigurationCancel(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      ),
      isFalse,
    );
  });
}
