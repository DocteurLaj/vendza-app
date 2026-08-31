import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> _queueFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/vendza_local_creates.json');
}

Future<String?> readLocalCreateQueueJson() async {
  final file = await _queueFile();
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeLocalCreateQueueJson(String json) async {
  final file = await _queueFile();
  await file.writeAsString(json);
}
