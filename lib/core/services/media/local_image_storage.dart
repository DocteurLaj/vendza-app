import 'package:image_picker/image_picker.dart';

import 'local_image_storage_io.dart'
    if (dart.library.html) 'local_image_storage_web.dart'
    as impl;

class LocalImageStorage {
  const LocalImageStorage._();

  static Future<String?> persist(XFile file) => impl.persistImage(file);
}
