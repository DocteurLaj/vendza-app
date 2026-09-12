import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/presantation/helpers/notification_presentation.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({
    super.key,
    required this.notification,
    required this.onOpen,
  });

  final NotificationModel notification;
  final ValueChanged<NotificationModel> onOpen;

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  bool isExpanded = false;

  void toggle() {
    final shouldExpand = !isExpanded;

    setState(() {
      isExpanded = shouldExpand;
    });

    if (shouldExpand) {
      widget.onOpen(widget.notification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final isUnread = !notification.isRead;
    final accentColor = _accentForType(context, notification.name);
    final actionLabel = notification.actionLabel;

    return AppInteractive(
      onTap: toggle,
      borderRadius: BorderRadius.circular(18),
      enableHoverElevation: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnread
                ? accentColor.withValues(alpha: 0.34)
                : AppColors.border(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark(context) ? 0.16 : 0.04,
              ),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationIcon(
                  icon: notification.icon,
                  color: accentColor,
                  isUnread: isUnread,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _CategoryChip(
                            label: notification.categoryLabel,
                            color: accentColor,
                          ),
                          if (isUnread) const _UnreadChip(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.description,
                        maxLines: isExpanded ? 5 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12.5,
                          height: 1.36,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: isExpanded ? 0.25 : 0,
                  child: Icon(
                    Icons.chevron_right,
                    color: accentColor.withValues(alpha: 0.58),
                    size: 23,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: isExpanded && actionLabel != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => widget.onOpen(notification),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: Text(actionLabel),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.icon,
    required this.color,
    required this.isUnread,
  });

  final IconData icon;
  final Color color;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isUnread ? 0.42 : 0.20),
        ),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _UnreadChip extends StatelessWidget {
  const _UnreadChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Nouveau',
        style: TextStyle(
          color: AppColors.success(context),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _accentForType(BuildContext context, String type) {
  final dark = AppColors.isDark(context);
  return switch (type) {
    'store_order' ||
    'order' => dark ? const Color(0xFF90CDF4) : const Color(0xFF2563EB),
    'promotion' => dark ? const Color(0xFFFFD166) : const Color(0xFFB7791F),
    'security' => dark ? const Color(0xFFFCA5A5) : const Color(0xFFC53030),
    'system' => dark ? const Color(0xFF67E8F9) : const Color(0xFF0E7490),
    _ => AppColors.accent(context),
  };
}
