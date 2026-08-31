import 'dart:convert';
import 'dart:typed_data';

bool isDataImagePath(String path) {
  final trimmed = path.trim();
  return trimmed.startsWith('data:image/') && trimmed.contains(';base64,');
}

Uint8List decodeDataImageBytes(String path) {
  final trimmed = path.trim();
  const marker = ';base64,';
  final index = trimmed.indexOf(marker);
  if (index == -1) {
    throw const FormatException('Image locale introuvable.');
  }
  return base64Decode(trimmed.substring(index + marker.length));
}
