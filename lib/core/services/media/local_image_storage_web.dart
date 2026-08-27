import 'package:image_picker/image_picker.dart';

Future<String?> persistImage(XFile file) async {
  final webPath = file.path.trim();
  return webPath.isEmpty ? null : webPath;
}
