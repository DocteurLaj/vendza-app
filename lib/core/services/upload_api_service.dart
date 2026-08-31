import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_exception.dart';

bool isRemoteMediaUrl(String path) {
  final trimmed = path.trim();
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}

class _TrackedUpload {
  _TrackedUpload(this.future);

  final Future<String> future;
  final List<void Function(double)> listeners = [];

  void emit(double value) {
    final progress = value.clamp(0.0, 1.0);
    for (final listener in List<void Function(double)>.from(listeners)) {
      listener(progress);
    }
  }
}

class UploadApiService {
  UploadApiService({ApiClient? client, http.Client? httpClient})
    : _client = client ?? apiClient,
      _httpClient = httpClient ?? http.Client();

  final ApiClient _client;
  final http.Client _httpClient;
  final Map<String, _TrackedUpload> _inFlight = {};

  Future<String> uploadLocalImage(
    String localPath, {
    String purpose = 'catalog',
    void Function(double progress)? onProgress,
  }) async {
    final trimmed = localPath.trim();
    if (trimmed.isEmpty) {
      throw const ApiException(message: 'Image locale introuvable.');
    }
    if (isRemoteMediaUrl(trimmed)) {
      onProgress?.call(1);
      return trimmed;
    }

    final key = '$purpose::$trimmed';
    final existing = _inFlight[key];
    if (existing != null) {
      if (onProgress != null) existing.listeners.add(onProgress);
      try {
        final url = await existing.future;
        onProgress?.call(1);
        return url;
      } finally {
        existing.listeners.remove(onProgress);
      }
    }

    late final _TrackedUpload tracked;
    tracked = _TrackedUpload(
      _uploadOnce(
        trimmed,
        purpose: purpose,
        onProgress: (value) {
          onProgress?.call(value);
          tracked.emit(value);
        },
      ),
    );
    _inFlight[key] = tracked;
    try {
      final url = await tracked.future;
      onProgress?.call(1);
      return url;
    } finally {
      if (identical(_inFlight[key], tracked)) {
        _inFlight.remove(key);
      }
    }
  }

  Future<String> _uploadOnce(
    String localPath, {
    required String purpose,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      throw const ApiException(message: 'Image locale introuvable.');
    }

    final size = await file.length();
    final maxBytes = purpose == 'avatar' ? 5 * 1024 * 1024 : 8 * 1024 * 1024;
    if (size <= 0) {
      throw const ApiException(message: 'Image locale introuvable.');
    }
    if (size > maxBytes) {
      throw ApiException(
        message: purpose == 'avatar'
            ? 'Image trop volumineuse (max 5 Mo).'
            : 'Image trop volumineuse (max 8 Mo).',
      );
    }

    onProgress?.call(0.08);

    final extension = localPath.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final fileName = localPath.split(Platform.pathSeparator).last;

    final presign = Map<String, dynamic>.from(
      await _client.post(
            ApiEndpoints.uploadImagePresign,
            authenticated: true,
            body: {'content_type': contentType, 'purpose': purpose},
          )
          as Map,
    );

    onProgress?.call(0.16);

    final upload = Map<String, dynamic>.from(presign['upload'] as Map);
    final url = upload['url'] as String;
    final fields = Map<String, String>.from(
      (upload['fields'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile(
        'file',
        http.ByteStream(_fileProgressStream(file, size, onProgress)),
        size,
        filename: fileName,
      ),
    );

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: "Echec de l'upload de l'image.",
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final publicUrl = (presign['public_url'] as String?)?.trim() ?? '';
    if (!isRemoteMediaUrl(publicUrl)) {
      throw const ApiException(message: "URL d'image invalide.");
    }
    onProgress?.call(1);
    return publicUrl;
  }

  Stream<List<int>> _fileProgressStream(
    File file,
    int total,
    void Function(double progress)? onProgress,
  ) {
    var sent = 0;
    return file.openRead().map((chunk) {
      sent += chunk.length;
      if (total > 0) {
        onProgress?.call((0.16 + 0.8 * (sent / total)).clamp(0.16, 0.96));
      }
      return chunk;
    });
  }

  Future<String> resolveImageUrl(
    String source, {
    String purpose = 'catalog',
    void Function(double progress)? onProgress,
  }) async {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return trimmed;
    if (isRemoteMediaUrl(trimmed) || trimmed.startsWith('assets/')) {
      onProgress?.call(1);
      return trimmed;
    }
    return uploadLocalImage(trimmed, purpose: purpose, onProgress: onProgress);
  }
}

final uploadApiService = UploadApiService();
