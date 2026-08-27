import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class AnimatedCircularRing extends StatefulWidget {
  const AnimatedCircularRing({
    super.key,
    required this.size,
    required this.child,
    this.ringWidth = 2.5,
    this.duration = const Duration(seconds: 3),
  });

  final double size;
  final Widget child;
  final double ringWidth;
  final Duration duration;

  @override
  State<AnimatedCircularRing> createState() => _AnimatedCircularRingState();
}

class _AnimatedCircularRingState extends State<AnimatedCircularRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final secondary = AppColors.success(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.all(widget.ringWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: _controller.value * 6.283185,
              colors: [
                accent,
                secondary,
                accent.withValues(alpha: 0.25),
                accent,
              ],
            ),
          ),
          child: child,
        );
      },
      child: ClipOval(child: widget.child),
    );
  }
}
