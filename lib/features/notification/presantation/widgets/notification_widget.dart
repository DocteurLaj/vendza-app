import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({
    super.key,
    required this.notification,
    required this.onMarkAsRead,
  });

  final NotificationModel notification;
  final ValueChanged<String> onMarkAsRead;

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

    if (shouldExpand && !widget.notification.isRead) {
      widget.onMarkAsRead(widget.notification.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !widget.notification.isRead;
    final accentColor = AppColors.accent(context);

    return AppInteractive(
      onTap: toggle,
      borderRadius: BorderRadius.circular(16),
      enableHoverElevation: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? accentColor.withValues(alpha: 0.32)
                : AppColors.border(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark(context) ? 0.14 : 0.03,
              ),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Image.asset(
                      widget.notification.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const _NotificationFallbackImage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.notification.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.success(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.notification.description,
                        maxLines: isExpanded ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                          height: 1.3,
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
                    color: accentColor.withValues(alpha: 0.50),
                    size: 22,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        widget.notification.description,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12.5,
                          height: 1.42,
                          fontWeight: FontWeight.w500,
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

class _NotificationFallbackImage extends StatelessWidget {
  const _NotificationFallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSurface(context),
      child: Icon(
        Icons.notifications_none_outlined,
        color: AppColors.accent(context),
      ),
    );
  }
}
