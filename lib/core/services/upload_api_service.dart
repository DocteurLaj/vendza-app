import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_exception.dart';

class UploadApiService {
  UploadApiService({ApiClient? client, http.Client? httpClient})
    : _client = client ?? apiClient,
      _httpClient = httpClient ?? http.Client();

  final ApiClient _client;
  final http.Client _httpClient;

  Future<String> uploadLocalImage(
    String localPath, {
    String purpose = 'catalog',
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

    final extension = localPath.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final presign = Map<String, dynamic>.from(
      await _client.post(
            ApiEndpoints.uploadImagePresign,
            authenticated: true,
            body: {'content_type': contentType, 'purpose': purpose},
          )
          as Map,
    );

    final upload = Map<String, dynamic>.from(presign['upload'] as Map);
    final url = upload['url'] as String;
    final fields = Map<String, String>.from(
      (upload['fields'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath('file', localPath));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: 'Echec de l\'upload de l\'image.',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final publicUrl = (presign['public_url'] as String?)?.trim() ?? '';
    if (!publicUrl.startsWith('http://') && !publicUrl.startsWith('https://')) {
      throw const ApiException(message: 'URL d\'image invalide.');
    }
    return publicUrl;
  }

  Future<String> resolveImageUrl(String source) async {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('assets/')) return trimmed;
    return uploadLocalImage(trimmed);
  }
}

final uploadApiService = UploadApiService();
