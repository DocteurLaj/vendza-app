import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';

class AppPopupShell extends StatelessWidget {
  const AppPopupShell({
    super.key,
    required this.child,
    this.size = PopupSize.medium,
    this.scrollable = false,
  });

  final Widget child;
  final PopupSize size;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxWidth = AppBreakpoints.popupMaxWidth(screenSize.width, size);
    final maxHeight = AppBreakpoints.popupMaxHeight(
      screenSize.height,
      scrollable: scrollable,
    );

    return Dialog(
      insetPadding: AppBreakpoints.popupInsetPadding(screenSize.width),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}
