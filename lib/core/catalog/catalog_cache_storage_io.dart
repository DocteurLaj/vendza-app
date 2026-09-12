import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> _cacheFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/vendza_catalog_cache.json');
}

Future<String?> readCatalogCacheJson() async {
  final file = await _cacheFile();
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeCatalogCacheJson(String json) async {
  final file = await _cacheFile();
  await file.writeAsString(json);
}
