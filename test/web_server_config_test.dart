import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web server applies security headers to cached and uncached responses',
    () {
      final nginx = File('deploy/nginx.conf').readAsStringSync();
      final headers = File('deploy/security-headers.inc').readAsStringSync();
      final dockerfile = File('Dockerfile').readAsStringSync();

      expect(headers, contains('Strict-Transport-Security'));
      expect(headers, contains('X-Content-Type-Options'));
      expect(headers, contains('X-Frame-Options'));
      expect(headers, contains('Content-Security-Policy'));
      expect(headers, contains("object-src 'none'"));
      expect(headers, contains("frame-ancestors 'self'"));

      // Nginx does not inherit server-level add_header directives in locations
      // that define Cache-Control, so each such location must include the policy.
      final cacheLocations = nginx.split('add_header Cache-Control').length - 1;
      final headerIncludes =
          nginx.split('include /etc/nginx/conf.d/security-headers.inc').length -
          1;
      expect(cacheLocations, greaterThan(0));
      expect(headerIncludes, cacheLocations + 1);
      expect(
        dockerfile,
        contains(
          'COPY deploy/security-headers.inc '
          '/etc/nginx/conf.d/security-headers.inc',
        ),
      );
    },
  );
}
