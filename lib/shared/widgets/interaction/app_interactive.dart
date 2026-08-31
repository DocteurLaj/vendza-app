import 'package:flutter/material.dart';
import 'package:vendza/core/constants/app_interaction_tokens.dart';
import 'package:vendza/core/constants/colors.dart';

class AppInteractive extends StatefulWidget {
  const AppInteractive({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.enabled = true,
    this.enableHoverLift = true,
    this.enableHoverElevation = false,
    this.cursor = SystemMouseCursors.click,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final bool enabled;
  final bool enableHoverLift;
  final bool enableHoverElevation;
  final MouseCursor cursor;
  final String? semanticLabel;

  @override
  State<AppInteractive> createState() => _AppInteractiveState();
}

class _AppInteractiveState extends State<AppInteractive> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isInteractive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setHovered(bool value) {
    if (!_isInteractive || !widget.enableHoverLift) return;
    if (_isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _setPressed(bool value) {
    if (!_isInteractive) return;
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  double get _scale {
    if (!_isInteractive) return 1;
    if (_isPressed) return AppInteractionTokens.pressedScale;
    if (_isHovered && widget.enableHoverLift) {
      return AppInteractionTokens.hoverScale;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.child;

    if (!_isInteractive) {
      return content;
    }

    final isDark = AppColors.isDark(context);
    final hoverDecoration = widget.enableHoverElevation && _isHovered
        ? BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark
                      ? AppInteractionTokens.hoverShadowAlphaDark
                      : AppInteractionTokens.hoverShadowAlphaLight,
                ),
                blurRadius: AppInteractionTokens.hoverShadowBlur,
                offset: AppInteractionTokens.hoverShadowOffset,
              ),
            ],
            border: Border.all(
              color: AppColors.border(
                context,
              ).withValues(alpha: isDark ? 0.85 : 1),
            ),
          )
        : null;

    Widget interactive = AnimatedScale(
      scale: _scale,
      duration: AppInteractionTokens.duration,
      curve: AppInteractionTokens.curve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onSecondaryTap: widget.onLongPress,
          borderRadius: widget.borderRadius,
          splashColor: AppColors.accent(
            context,
          ).withValues(alpha: AppInteractionTokens.splashAlpha),
          highlightColor: AppColors.accent(
            context,
          ).withValues(alpha: AppInteractionTokens.highlightAlpha),
          onHover: _setHovered,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          child: hoverDecoration == null
              ? content
              : AnimatedContainer(
                  duration: AppInteractionTokens.duration,
                  curve: AppInteractionTokens.curve,
                  decoration: hoverDecoration,
                  child: content,
                ),
        ),
      ),
    );

    interactive = MouseRegion(
      cursor: widget.enabled ? widget.cursor : SystemMouseCursors.basic,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: interactive,
    );

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      enabled: widget.enabled,
      child: interactive,
    );
  }
}

extension AppInteractiveExtension on Widget {
  Widget appInteractive({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
    bool enabled = true,
    bool enableHoverLift = true,
    bool enableHoverElevation = false,
    MouseCursor cursor = SystemMouseCursors.click,
    String? semanticLabel,
  }) {
    return AppInteractive(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      enabled: enabled,
      enableHoverLift: enableHoverLift,
      enableHoverElevation: enableHoverElevation,
      cursor: cursor,
      semanticLabel: semanticLabel,
      child: this,
    );
  }
}
