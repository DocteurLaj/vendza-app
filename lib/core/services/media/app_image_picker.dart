import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vendza/core/services/media/local_image_storage.dart';
import 'package:vendza/shared/widgets/media/image_source_sheet.dart';

import 'app_image_picker_io.dart'
    if (dart.library.html) 'app_image_picker_web.dart'
    as platform;

Future<String?> pickAppImage(BuildContext context, {required String title}) {
  return AppImagePicker.instance.pick(context, title: title);
}

class AppImagePicker {
  AppImagePicker._();

  static final AppImagePicker instance = AppImagePicker._();
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> pick(BuildContext context, {required String title}) async {
    try {
      if (kIsWeb || platform.isMobile) {
        final source = await showImageSourceSheet(
          context: context,
          title: title,
        );
        if (source == null || !context.mounted) return null;

        return _persistPickedFile(
          await _imagePicker.pickImage(source: source, imageQuality: 85),
        );
      }

      if (platform.useFileExplorer) {
        return _pickFromFileExplorer();
      }

      return _persistPickedFile(
        await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        ),
      );
    } catch (error) {
      if (!context.mounted) return null;
      _showError(context, 'Impossible de sélectionner l\'image.');
      return null;
    }
  }

  Future<String?> _pickFromFileExplorer() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final platformFile = result.files.single;
    if (platformFile.path != null && platformFile.path!.isNotEmpty) {
      return LocalImageStorage.persist(XFile(platformFile.path!));
    }

    if (platformFile.bytes != null) {
      final temp = XFile.fromData(
        platformFile.bytes!,
        name: platformFile.name,
        mimeType: platformFile.extension != null
            ? 'image/${platformFile.extension}'
            : null,
      );
      return LocalImageStorage.persist(temp);
    }

    return null;
  }

  Future<String?> _persistPickedFile(XFile? file) async {
    if (file == null) return null;
    return LocalImageStorage.persist(file);
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
