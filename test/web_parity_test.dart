import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/media/data_image.dart';
import 'package:vendza/core/services/share/share_link_builder.dart';

void main() {
  test('decodes a data image URL used by the web catalog', () {
    final bytes = utf8.encode('vendza');
    final path = 'data:image/png;base64,${base64Encode(bytes)}';

    expect(isDataImagePath(path), isTrue);
    expect(decodeDataImageBytes(path), bytes);
  });

  test('share links point at the live web app host', () {
    expect(ShareLinkBuilder.productUrl('42'), 'https://app.vendza.online/p/42');
    expect(ShareLinkBuilder.storeUrl('7'), 'https://app.vendza.online/store/7');
  });
  test('Android declares runtime notification permission', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
  });
}
