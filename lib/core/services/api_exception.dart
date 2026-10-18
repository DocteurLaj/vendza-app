class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final Object? body;

  static const planLimitCode = 'plan_limit_reached';

  Map<String, dynamic>? get bodyAsMap {
    if (body is Map<String, dynamic>) return body as Map<String, dynamic>;
    if (body is Map) return Map<String, dynamic>.from(body as Map);
    return null;
  }

  /// Machine-readable error code, from the envelope (`code`) or the
  /// structured `details`/`detail` map (`error`).
  String? get code {
    final map = bodyAsMap;
    if (map == null) return null;
    final envelopeCode = map['code'];
    if (envelopeCode is String &&
        envelopeCode.isNotEmpty &&
        envelopeCode != 'http_error') {
      return envelopeCode;
    }
    for (final key in const ['details', 'detail']) {
      final nested = map[key];
      if (nested is Map && nested['error'] is String) {
        return nested['error'] as String;
      }
    }
    final error = map['error'];
    if (error is String && error.isNotEmpty) return error;
    return envelopeCode is String && envelopeCode.isNotEmpty
        ? envelopeCode
        : null;
  }

  /// Structured plan-limit payload (`message`, `current_plan`, …) or null.
  ///
  /// Supported shapes:
  /// * current API envelope: `{success:false, message, code:'plan_limit_reached',
  ///   details:{error:'plan_limit_reached', message, current_plan, ...}}`
  /// * FastAPI default: `{detail:{error:'plan_limit_reached', ...}}`
  /// * flat: `{error|code:'plan_limit_reached', message, ...}`
  /// * legacy flattened repr: `{message:"{'error': 'plan_limit_reached', ...}"}`
  Map<String, dynamic>? get planLimitDetail {
    final map = bodyAsMap;
    if (map == null) return null;
    final envelopeIsPlanLimit = map['code'] == planLimitCode;

    for (final key in const ['details', 'detail']) {
      final nested = map[key];
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        if (nestedMap['error'] == planLimitCode ||
            nestedMap['code'] == planLimitCode ||
            envelopeIsPlanLimit) {
          final nestedMessage = nestedMap['message'];
          if (nestedMessage is! String || nestedMessage.trim().isEmpty) {
            final envelopeMessage = _cleanMessage(map['message']);
            if (envelopeMessage != null) {
              nestedMap['message'] = envelopeMessage;
            }
          }
          nestedMap['error'] ??= planLimitCode;
          return nestedMap;
        }
      }
    }

    if (map['error'] == planLimitCode || envelopeIsPlanLimit) {
      return map;
    }

    final legacy = _parsePythonReprDetail(map['message']);
    if (legacy != null && legacy['error'] == planLimitCode) return legacy;
    return null;
  }

  bool get isPlanLimitReached => statusCode == 402 && planLimitDetail != null;

  /// Human-readable message, never a serialized dict/repr.
  String get displayMessage {
    final planMessage = _cleanMessage(planLimitDetail?['message']);
    if (planMessage != null) return planMessage;
    final legacy = _parsePythonReprDetail(message);
    final legacyMessage = _cleanMessage(legacy?['message']);
    if (legacyMessage != null) return legacyMessage;
    if (_looksLikeSerializedMap(message)) return 'Une erreur est survenue.';
    return message;
  }

  /// Extracts a human message from a decoded error body.
  static String messageFromBody(Object? decodedBody) {
    const fallback = 'Une erreur est survenue.';
    if (decodedBody is! Map) return fallback;
    final map = Map<String, dynamic>.from(decodedBody);
    final detail = map['detail'];
    if (detail is String && detail.isNotEmpty) {
      return _humanize(detail) ?? fallback;
    }
    for (final key in const ['detail', 'details']) {
      final nested = map[key];
      if (nested is Map) {
        final nestedMessage = _cleanMessage(nested['message']);
        if (nestedMessage != null) return nestedMessage;
      }
    }
    final message = map['message'];
    if (message is String && message.isNotEmpty) {
      return _humanize(message) ?? fallback;
    }
    return fallback;
  }

  static String? _humanize(String raw) {
    final legacy = _parsePythonReprDetail(raw);
    final legacyMessage = _cleanMessage(legacy?['message']);
    if (legacyMessage != null) return legacyMessage;
    if (_looksLikeSerializedMap(raw)) return null;
    return raw;
  }

  static String? _cleanMessage(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || _looksLikeSerializedMap(trimmed)) return null;
    return trimmed;
  }

  static bool _looksLikeSerializedMap(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith('{') && trimmed.endsWith('}');
  }

  /// Best-effort parse of a Python dict repr with string/None/bool/number
  /// values, e.g. `{'error': 'plan_limit_reached', 'message': "L'offre..."}`.
  static Map<String, dynamic>? _parsePythonReprDetail(Object? value) {
    if (value is! String || !_looksLikeSerializedMap(value)) return null;
    final result = <String, dynamic>{};
    final pattern = RegExp(
      r"""['"]([A-Za-z0-9_]+)['"]\s*:\s*('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"|None|True|False|-?\d+(?:\.\d+)?)""",
    );
    for (final match in pattern.allMatches(value)) {
      final key = match.group(1)!;
      final raw = match.group(2)!;
      Object? parsed;
      if (raw == 'None') {
        parsed = null;
      } else if (raw == 'True') {
        parsed = true;
      } else if (raw == 'False') {
        parsed = false;
      } else if (raw.startsWith("'") || raw.startsWith('"')) {
        parsed = raw
            .substring(1, raw.length - 1)
            .replaceAll(r"\'", "'")
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', r'\');
      } else {
        parsed = num.tryParse(raw);
      }
      result[key] = parsed;
    }
    return result.isEmpty ? null : result;
  }

  @override
  String toString() {
    final status = statusCode == null ? '' : ' [$statusCode]';
    return 'ApiException$status: $message';
  }
}
