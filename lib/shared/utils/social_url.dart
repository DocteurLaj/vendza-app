bool isHttpUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

bool isInstagramUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.host.isEmpty) return false;
  final host = uri.host.toLowerCase();
  return host == 'instagram.com' || host.endsWith('.instagram.com');
}

bool isFacebookUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.host.isEmpty) return false;
  final host = uri.host.toLowerCase();
  return host == 'facebook.com' ||
      host.endsWith('.facebook.com') ||
      host == 'fb.com' ||
      host.endsWith('.fb.com') ||
      host == 'fb.me' ||
      host.endsWith('.fb.me');
}

String? validateRequiredHttpUrl(String value, {required String label}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!isHttpUrl(trimmed)) {
    return '$label doit être un lien complet (https://...).';
  }
  return null;
}

String? validateInstagramUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!isHttpUrl(trimmed) || !isInstagramUrl(trimmed)) {
    return 'Instagram doit être un lien complet (https://instagram.com/...).';
  }
  return null;
}

String? validateFacebookUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!isHttpUrl(trimmed) || !isFacebookUrl(trimmed)) {
    return 'Facebook doit être un lien complet (https://facebook.com/...).';
  }
  return null;
}
