import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CarouselScrollScope extends StatelessWidget {
  const CarouselScrollScope({
    super.key,
    required this.child,
    required this.onUserScrollStart,
    required this.onUserScrollEnd,
    this.enableMouseAndTrackpad = true,
  });

  final Widget child;
  final VoidCallback onUserScrollStart;
  final VoidCallback onUserScrollEnd;
  final bool enableMouseAndTrackpad;

  @override
  Widget build(BuildContext context) {
    Widget scopedChild = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          onUserScrollStart();
        } else if (notification is ScrollEndNotification &&
            notification.dragDetails != null) {
          onUserScrollEnd();
        }
        return false;
      },
      child: child,
    );

    if (!enableMouseAndTrackpad) return scopedChild;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: scopedChild,
    );
  }
}

const carouselListPhysics = BouncingScrollPhysics(
  parent: AlwaysScrollableScrollPhysics(),
);
