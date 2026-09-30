import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class AttentionBadge extends StatelessWidget {
  const AttentionBadge({super.key, required this.count, this.small = false});

  final int count;
  final bool small;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final display = count > 99 ? '99+' : '$count';
    final size = small ? 15.0 : 18.0;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: EdgeInsets.symmetric(horizontal: small ? 4 : 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE74747),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.isDark(context)
              ? AppColors.darkSurface
              : Colors.white,
          width: small ? 1 : 1.3,
        ),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 8 : 10,
          fontWeight: FontWeight.w900,
          height: 1,
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
      width: 30,
      height: 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, size: iconSize),
          Positioned(
            right: -4,
            top: -3,
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
