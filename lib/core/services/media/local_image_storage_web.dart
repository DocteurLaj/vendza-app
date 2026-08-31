import 'dart:convert';

import 'package:image_picker/image_picker.dart';

Future<String?> persistImage(XFile file) async {
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;
  final mime = file.mimeType?.trim().toLowerCase() ?? '';
  final contentType = mime.startsWith('image/') ? mime : 'image/jpeg';
  return 'data:$contentType;base64,${base64Encode(bytes)}';
}
