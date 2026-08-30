import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/shared/utils/phone_number.dart';
import 'package:vendza/shared/utils/social_url.dart';

void main() {
  group('parsePhoneNumber', () {
    test('defaults empty input to +243', () {
      final parsed = parsePhoneNumber('');
      expect(parsed.country.dialCode, '243');
      expect(parsed.national, isEmpty);
      expect(parsed.isValid, isFalse);
    });

    test('accepts a valid Congolese number', () {
      final parsed = parsePhoneNumber('0970123456');
      expect(parsed.e164, '+243970123456');
      expect(parsed.isValid, isTrue);
    });

    test('keeps E.164 as stored form', () {
      final parsed = parsePhoneNumber('+243970123456');
      expect(parsed.country.iso, 'CD');
      expect(parsed.national, '970123456');
      expect(parsed.e164, '+243970123456');
    });
  });

  group('social urls', () {
    test('rejects a phone number as Instagram', () {
      expect(validateInstagramUrl('+243970123456'), isNotNull);
    });

    test('accepts a complete Instagram URL', () {
      expect(
        validateInstagramUrl('https://instagram.com/vendza'),
        isNull,
      );
    });

    test('accepts facebook.com and fb.com', () {
      expect(validateFacebookUrl('https://www.facebook.com/vendza'), isNull);
      expect(validateFacebookUrl('https://fb.com/vendza'), isNull);
    });
  });
}
