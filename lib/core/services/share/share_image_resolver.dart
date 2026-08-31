import 'package:share_plus/share_plus.dart';

import 'share_image_resolver_stub.dart'
    if (dart.library.io) 'share_image_resolver_io.dart' as impl;

class ShareImageResolver {
  const ShareImageResolver._();

  static Future<XFile?> resolve(String imagePath) =>
      impl.resolveShareImage(imagePath);
}
