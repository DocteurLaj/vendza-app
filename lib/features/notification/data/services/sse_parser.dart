import 'dart:convert';

class SseMessage {
  const SseMessage({required this.event, required this.data});

  final String event;
  final Map<String, dynamic> data;
}

List<SseMessage> parseSseMessages(String chunk) {
  final messages = <SseMessage>[];
  final normalized = chunk.replaceAll('\r\n', '\n');
  for (final block in normalized.split('\n\n')) {
    final trimmed = block.trim();
    if (trimmed.isEmpty || trimmed.startsWith(':')) continue;
    var event = 'message';
    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        event = line.substring('event:'.length).trim();
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring('data:'.length).trimLeft());
      }
    }
    if (dataLines.isEmpty) continue;
    final decoded = jsonDecode(dataLines.join('\n'));
    if (decoded is Map) {
      messages.add(
        SseMessage(event: event, data: Map<String, dynamic>.from(decoded)),
      );
    }
  }
  return messages;
}
