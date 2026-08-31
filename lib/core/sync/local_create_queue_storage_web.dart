import 'package:web/web.dart' as web;

const _storageKey = 'vendza_local_creates';

Future<String?> readLocalCreateQueueJson() async {
  final value = web.window.localStorage.getItem(_storageKey);
  if (value == null || value.trim().isEmpty) return null;
  return value;
}

Future<void> writeLocalCreateQueueJson(String json) async {
  web.window.localStorage.setItem(_storageKey, json);
}
