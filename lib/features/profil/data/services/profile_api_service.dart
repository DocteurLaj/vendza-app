import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/upload_api_service.dart';
import 'package:vendza/core/session/current_user_store.dart';

class ProfileApiService {
  ProfileApiService({ApiClient? client, UploadApiService? uploadApi})
    : _client = client ?? apiClient,
      _uploadApi = uploadApi ?? uploadApiService;

  final ApiClient _client;
  final UploadApiService _uploadApi;

  Future<Map<String, dynamic>> updateFullName(String fullName) async {
    final response = await _client.put(
      ApiEndpoints.profileFullName,
      authenticated: true,
      body: {'new_fullname': fullName},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updatePhone(String phone) async {
    final response = await _client.put(
      ApiEndpoints.profilePhone,
      authenticated: true,
      body: {'new_phone': phone},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> updateAvatar(String avatarUrl) async {
    final sanitized = sanitizeAvatarUrl(avatarUrl);
    if (sanitized.isEmpty) {
      throw const ApiException(message: 'URL d\'avatar invalide.');
    }
    final response = await _client.put(
      ApiEndpoints.profileAvatar,
      authenticated: true,
      body: {'new_avatar': sanitized},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<String> savePickedAvatar(String localPath) async {
    final trimmed = localPath.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('assets/')) {
      throw const ApiException(message: 'Image locale invalide.');
    }

    final uploaded = await _uploadApi.uploadLocalImage(
      trimmed,
      purpose: 'avatar',
    );
    final response = await updateAvatar(uploaded);
    final saved = sanitizeAvatarUrl(
      (response['avatarUrl'] as String?) ?? (response['avatar'] as String?),
    );
    if (saved.isEmpty) {
      throw const ApiException(message: 'URL d\'avatar invalide.');
    }
    return saved;
  }

  Future<Map<String, dynamic>> updateAddress({required String address}) async {
    final response = await _client.put(
      ApiEndpoints.profileAddress,
      authenticated: true,
      body: {'new_city': address.trim()},
    );
    return Map<String, dynamic>.from(response as Map);
  }
}
