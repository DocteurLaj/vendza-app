import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';

class NotificationFilterToggle extends StatelessWidget {
  const NotificationFilterToggle({
    super.key,
    required this.showUnread,
    required this.onChanged,
  });

  final bool showUnread;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.searchSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: showUnread
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.border(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppColors.isDark(context) ? 0.16 : 0.06,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _buildButton(context, "Non lues", true),
              _buildButton(context, "Lues", false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, bool value) {
    final isActive = showUnread == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 38,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: isActive
                    ? AppColors.textPrimary(context)
                    : AppColors.textSecondary(context),
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              ),
              child: Text(text),
            ),
          ),
        ),
      ),
    );
  }
}
