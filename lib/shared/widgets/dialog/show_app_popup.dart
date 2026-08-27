import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_shell.dart';

Future<T?> showAppPopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  PopupSize size = PopupSize.medium,
  bool barrierDismissible = true,
  bool scrollable = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppPopupShell(
      size: size,
      scrollable: scrollable,
      child: builder(context),
    ),
  );
}
