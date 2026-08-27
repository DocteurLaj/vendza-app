import 'package:flutter/widgets.dart';

Widget buildLocalImage({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  required Widget fallback,
}) {
  return Image.network(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, _, _) => fallback,
  );
}
