import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android App Links are verifiable for app.vendza.online', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final nginx = File('deploy/nginx.conf').readAsStringSync();
    final links =
        jsonDecode(File('web/.well-known/assetlinks.json').readAsStringSync())
            as List<dynamic>;

    // Every https intent-filter on app.vendza.online must ask for verification,
    // otherwise Android shows a chooser / opens the browser instead of the app.
    final httpsFilters = manifest
        .split('<intent-filter')
        .skip(1)
        .map((block) => block.split('</intent-filter>').first)
        .where((block) => block.contains('android:scheme="https"'))
        .toList();
    expect(httpsFilters, isNotEmpty);
    for (final filter in httpsFilters) {
      expect(filter, contains('android:autoVerify="true"'));
    }

    final entry = links.single as Map<String, dynamic>;
    final target = entry['target'] as Map<String, dynamic>;
    expect(
      entry['relation'],
      contains('delegate_permission/common.handle_all_urls'),
    );
    expect(target['namespace'], 'android_app');
    expect(gradle, contains('applicationId = "${target['package_name']}"'));
    final fingerprints = (target['sha256_cert_fingerprints'] as List)
        .cast<String>();
    expect(fingerprints, isNotEmpty);
    for (final fp in fingerprints) {
      expect(fp, matches(RegExp(r'^([0-9A-F]{2}:){31}[0-9A-F]{2}$')));
    }

    // Served as JSON and not swallowed by the SPA fallback.
    expect(nginx, contains('location = /.well-known/assetlinks.json'));
    expect(nginx, contains('default_type application/json'));
  });
}
