import 'package:flutter/material.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/media/app_image_picker.dart';
import 'package:vendza/core/services/upload_api_service.dart';

enum ImageUploadStatus { idle, uploading, success, failed }

typedef ImageUploader = Future<String> Function(String path, {String purpose});

class ImageUploadController extends ChangeNotifier {
  ImageUploadController({
    String? initialUrl,
    this.purpose = 'catalog',
    this.pickTitle = "Choisir une image",
    ImageUploader? uploader,
  }) : _uploader =
           uploader ??
           ((path, {purpose = 'catalog'}) =>
               uploadApiService.uploadLocalImage(path, purpose: purpose)) {
    final url = (initialUrl ?? '').trim();
    if (url.startsWith('http://') || url.startsWith('https://')) {
      _remoteUrl = url;
      _previewUrl = url;
      _status = ImageUploadStatus.success;
    } else if (url.isNotEmpty) {
      _localPath = url;
      _previewUrl = url;
    }
  }

  final String purpose;
  final String pickTitle;
  final ImageUploader _uploader;

  ImageUploadStatus _status = ImageUploadStatus.idle;
  String _previewUrl = '';
  String? _remoteUrl;
  String? _localPath;
  String? _errorMessage;
  Future<void>? _inFlight;

  ImageUploadStatus get status => _status;
  String get previewUrl => _previewUrl;
  String? get remoteUrl => _remoteUrl;
  String? get errorMessage => _errorMessage;
  bool get isUploading => _status == ImageUploadStatus.uploading;
  bool get hasFailed => _status == ImageUploadStatus.failed;
  bool get blocksSubmit => isUploading || hasFailed;
  bool get hasImage => _previewUrl.trim().isNotEmpty;

  Future<void> pickAndUpload(BuildContext context) async {
    if (isUploading) return;
    final selected = await pickAppImage(context, title: pickTitle);
    if (selected == null || selected.trim().isEmpty) return;
    _localPath = selected.trim();
    _previewUrl = _localPath!;
    _remoteUrl = null;
    await _uploadCurrent();
  }

  Future<void> retry() => _uploadCurrent();

  Future<String> ensureRemoteUrl() async {
    final existing = _remoteUrl?.trim() ?? '';
    if (existing.startsWith('http://') || existing.startsWith('https://')) {
      return existing;
    }
    if (_localPath == null || _localPath!.trim().isEmpty) {
      throw const ApiException(
        message: 'Ajoutez une image avant de continuer.',
      );
    }
    await _uploadCurrent();
    final uploaded = _remoteUrl?.trim() ?? '';
    if (uploaded.isEmpty) {
      throw ApiException(
        message: _errorMessage ?? "Echec de l'upload de l'image.",
      );
    }
    return uploaded;
  }

  Future<void> _uploadCurrent() async {
    final path = _localPath?.trim() ?? '';
    if (path.isEmpty) return;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      _remoteUrl = path;
      _previewUrl = path;
      _status = ImageUploadStatus.success;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final future = _runUpload(path);
    _inFlight = future;
    try {
      await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  Future<void> _runUpload(String path) async {
    _status = ImageUploadStatus.uploading;
    _errorMessage = null;
    notifyListeners();
    try {
      final url = await _uploader(path, purpose: purpose);
      _remoteUrl = url;
      _previewUrl = url;
      _status = ImageUploadStatus.success;
      _errorMessage = null;
    } on ApiException catch (error) {
      _status = ImageUploadStatus.failed;
      _errorMessage = error.message;
    } on Object {
      _status = ImageUploadStatus.failed;
      _errorMessage = "Echec de l'upload de l'image.";
    }
    notifyListeners();
  }
}
