class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final Object? body;

  Map<String, dynamic>? get bodyAsMap {
    if (body is Map<String, dynamic>) return body as Map<String, dynamic>;
    if (body is Map) return Map<String, dynamic>.from(body as Map);
    return null;
  }

  Map<String, dynamic>? get planLimitDetail {
    final map = bodyAsMap;
    if (map == null) return null;
    final detail = map['detail'];
    if (detail is Map) {
      final detailMap = Map<String, dynamic>.from(detail);
      if (detailMap['error'] == 'plan_limit_reached') return detailMap;
    }
    final details = map['details'];
    if (details is Map) {
      final detailsMap = Map<String, dynamic>.from(details);
      if (detailsMap['error'] == 'plan_limit_reached') return detailsMap;
    }
    if (map['error'] == 'plan_limit_reached' ||
        map['code'] == 'plan_limit_reached') {
      return map;
    }
    return null;
  }

  bool get isPlanLimitReached => statusCode == 402 && planLimitDetail != null;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' [$statusCode]';
    return 'ApiException$status: $message';
  }
}
