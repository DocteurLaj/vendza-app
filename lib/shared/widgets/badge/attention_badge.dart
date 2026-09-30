import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class AttentionBadge extends StatelessWidget {
  const AttentionBadge({
    super.key,
    required this.count,
    this.small = false,
    this.label,
  });

  final int count;
  final bool small;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final display = label ?? (count > 99 ? '99+' : '$count');
    final accent = AppColors.accent(context);
    final alert = const Color(0xFFE74747);
    final minHeight = small ? 17.0 : 22.0;
    return Semantics(
      label: '$display notification${count > 1 ? 's' : ''} à consulter',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minWidth: minHeight, minHeight: minHeight),
        padding: EdgeInsets.symmetric(horizontal: small ? 5 : 8, vertical: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [alert, Color.lerp(alert, accent, 0.22) ?? alert],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.isDark(context)
                ? AppColors.darkSurface.withValues(alpha: 0.95)
                : Colors.white,
            width: small ? 1.4 : 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: alert.withValues(
                alpha: AppColors.isDark(context) ? 0.28 : 0.20,
              ),
              blurRadius: small ? 8 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          display,
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 8.5 : 11,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

class BadgedIcon extends StatelessWidget {
  const BadgedIcon({
    super.key,
    required this.icon,
    required this.count,
    this.iconSize,
  });

  final IconData icon;
  final int count;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, size: iconSize),
          Positioned(
            right: -6,
            top: -4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: AttentionBadge(key: ValueKey(count), count: count),
            ),
          ),
        ],
      ),
    );
  }
}
