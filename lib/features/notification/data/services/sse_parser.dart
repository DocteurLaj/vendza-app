import 'dart:convert';

class SseMessage {
  const SseMessage({required this.event, required this.data, this.id});

  final String event;
  final Map<String, dynamic> data;
  final String? id;
}

/// Incremental, line-based Server-Sent Events parser.
///
/// Network chunks may split a frame (or even a line, or a `\r\n` pair) at any
/// byte. The parser keeps the unterminated tail between calls to [add] and
/// only dispatches an event once its terminating blank line has been read.
/// Malformed JSON payloads are dropped instead of throwing, so a single bad
/// frame can never kill the stream.
class SseStreamParser {
  String _pending = '';
  bool _skipLeadingLf = false;
  String _event = '';
  String? _id;
  final List<String> _dataLines = [];

  /// The last `id:` value received, suitable for a `Last-Event-ID` header.
  String? lastEventId;

  /// Feeds a decoded text chunk and returns the events completed by it.
  List<SseMessage> add(String chunk) {
    if (chunk.isEmpty) return const [];
    var text = chunk;
    if (_skipLeadingLf) {
      _skipLeadingLf = false;
      if (text.startsWith('\n')) text = text.substring(1);
    }
    _pending += text;

    final messages = <SseMessage>[];
    var start = 0;
    for (var i = 0; i < _pending.length; i++) {
      final char = _pending.codeUnitAt(i);
      if (char != 0x0A && char != 0x0D) continue;
      final line = _pending.substring(start, i);
      if (char == 0x0D) {
        if (i + 1 < _pending.length) {
          if (_pending.codeUnitAt(i + 1) == 0x0A) i++;
        } else {
          // A trailing CR may be the first half of a CRLF split across chunks.
          _skipLeadingLf = true;
        }
      }
      start = i + 1;
      final message = _processLine(line);
      if (message != null) messages.add(message);
    }
    _pending = _pending.substring(start);
    return messages;
  }

  /// Clears any partial frame, e.g. when the connection is re-established.
  void reset() {
    _pending = '';
    _skipLeadingLf = false;
    _event = '';
    _id = null;
    _dataLines.clear();
  }

  SseMessage? _processLine(String line) {
    if (line.isEmpty) return _dispatch();
    if (line.startsWith(':')) return null;

    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);

    switch (field) {
      case 'event':
        _event = value;
      case 'data':
        _dataLines.add(value);
      case 'id':
        if (!value.contains('\u0000')) _id = value;
      default:
        // `retry` and unknown fields are ignored.
        break;
    }
    return null;
  }

  SseMessage? _dispatch() {
    final event = _event.isEmpty ? 'message' : _event;
    final id = _id;
    final hasData = _dataLines.isNotEmpty;
    final payload = _dataLines.join('\n');
    _event = '';
    _dataLines.clear();
    if (id != null) lastEventId = id;
    if (!hasData) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    return SseMessage(
      event: event,
      data: Map<String, dynamic>.from(decoded),
      id: id,
    );
  }
}

/// Parses a complete SSE payload (all frames terminated by a blank line).
List<SseMessage> parseSseMessages(String chunk) {
  return SseStreamParser().add(chunk);
}
