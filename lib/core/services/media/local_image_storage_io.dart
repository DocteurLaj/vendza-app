import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> persistImage(XFile file) async {
  final sourcePath = file.path.trim();
  if (sourcePath.isEmpty) return null;

  final documentsDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory('${documentsDir.path}/images');
  if (!await imagesDir.exists()) {
    await imagesDir.create(recursive: true);
  }

  final extension = _resolveExtension(sourcePath, file.name);
  final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
  final destination = File('${imagesDir.path}/$fileName');

  await File(sourcePath).copy(destination.path);
  return destination.path;
}

String _resolveExtension(String sourcePath, String fileName) {
  final dotInName = fileName.lastIndexOf('.');
  if (dotInName != -1) {
    return fileName.substring(dotInName).toLowerCase();
  }

  final dotInPath = sourcePath.lastIndexOf('.');
  if (dotInPath != -1) {
    return sourcePath.substring(dotInPath).toLowerCase();
  }

  return '.jpg';
}
