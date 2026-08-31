import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

Future<XFile?> resolveShareImage(String imagePath) async {
  final trimmed = imagePath.trim();
  if (trimmed.isEmpty) return null;

  try {
    if (SmartImage.isAssetPath(trimmed)) {
      return _assetToXFile(trimmed);
    }

    if (SmartImage.isNetworkPath(trimmed)) {
      return _networkToXFile(trimmed);
    }

    final file = File(trimmed);
    if (await file.exists()) {
      return XFile(trimmed);
    }
  } catch (_) {
    return null;
  }

  return null;
}

Future<XFile?> _assetToXFile(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final tempDir = await getTemporaryDirectory();
  final fileName =
      'vendza_share_${DateTime.now().millisecondsSinceEpoch}${_extension(assetPath)}';
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
  return XFile(file.path);
}

Future<XFile?> _networkToXFile(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) return null;

  final tempDir = await getTemporaryDirectory();
  final fileName =
      'vendza_share_${DateTime.now().millisecondsSinceEpoch}${_extensionFromUrl(url, response.headers['content-type'])}';
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(response.bodyBytes);
  return XFile(file.path);
}

String _extension(String value) {
  final dot = value.lastIndexOf('.');
  if (dot == -1) return '.jpg';
  return value.substring(dot);
}

String _extensionFromUrl(String url, String? contentType) {
  final fromUrl = _extension(url.split('?').first);
  if (fromUrl.length > 1) return fromUrl;

  if (contentType == null) return '.jpg';
  if (contentType.contains('png')) return '.png';
  if (contentType.contains('webp')) return '.webp';
  if (contentType.contains('gif')) return '.gif';
  return '.jpg';
}
