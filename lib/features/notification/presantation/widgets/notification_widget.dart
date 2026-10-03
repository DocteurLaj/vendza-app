import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/presantation/helpers/notification_presentation.dart';
import 'package:vendza/shared/utils/date_time_label.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/media/context_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationWidget
// ─────────────────────────────────────────────────────────────────────────────

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({
    super.key,
    required this.notification,
    required this.onOpen,
    this.onDelete,
  });

  final NotificationModel notification;
  final ValueChanged<NotificationModel> onOpen;
  final ValueChanged<NotificationModel>? onDelete;

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  bool isExpanded = false;

  void toggle() {
    final shouldExpand = !isExpanded;
    setState(() => isExpanded = shouldExpand);
    if (shouldExpand) widget.onOpen(widget.notification);
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final isUnread = !notification.isRead;
    final accent = _accentForType(context, notification.name);
    final actionLabel = notification.actionLabel;

    return AppInteractive(
      onTap: toggle,
      borderRadius: BorderRadius.circular(16),
      enableHoverElevation: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? accent.withValues(alpha: 0.30)
                : AppColors.border(context),
            width: isUnread ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark(context) ? 0.14 : 0.04,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Main row: avatar + content + actions ──────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar (image or icon-in-circle)
                  _NotifAvatar(
                    imageUrl: notification.imageUrl,
                    icon: notification.icon,
                    accentColor: accent,
                  ),
                  const SizedBox(width: 12),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line 1: category chip + unread dot + time
                        _MetaRow(
                          categoryLabel: notification.categoryLabel,
                          accentColor: accent,
                          isUnread: isUnread,
                          createdAt: notification.createdAt,
                        ),
                        const SizedBox(height: 5),

                        // Line 2: title
                        Text(
                          notification.storeName ?? notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),

                        // Line 3: product name (if present)
                        if ((notification.productName ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            notification.productName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.80),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],

                        const SizedBox(height: 5),

                        // Line 4: description body
                        Text(
                          notification.description,
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right column: delete + chevron
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (widget.onDelete != null)
                        GestureDetector(
                          onTap: () => widget.onDelete!(notification),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 17,
                              color: AppColors.textSecondary(context)
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 4),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: isExpanded ? 0.25 : 0,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: accent.withValues(alpha: 0.55),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Expanded CTA ──────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: isExpanded && actionLabel != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12, left: 56),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => widget.onOpen(notification),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                          label: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _NotifAvatar extends StatelessWidget {
  const _NotifAvatar({
    required this.imageUrl,
    required this.icon,
    required this.accentColor,
  });

  final String imageUrl;
  final IconData icon;
  final Color accentColor;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    if (hasImage) {
      return VendzaContextImage(
        imageUrl: imageUrl,
        icon: icon,
        size: _size,
      );
    }

    // Icon-in-circle fallback — more intentional than an empty image slot
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(_size * 0.28),
      ),
      child: Icon(icon, color: accentColor, size: 22),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta row: category · unread dot · time
// ─────────────────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.categoryLabel,
    required this.accentColor,
    required this.isUnread,
    required this.createdAt,
  });

  final String categoryLabel;
  final Color accentColor;
  final bool isUnread;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Category chip
        _CategoryChip(label: categoryLabel, color: accentColor),

        // Unread indicator — a small dot, not a chip
        if (isUnread) ...[
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.success(context),
              shape: BoxShape.circle,
            ),
          ),
        ],

        // Spacer then time
        if (createdAt != null) ...[
          const SizedBox(width: 6),
          Text(
            vendzaDateTimeLabel(createdAt!),
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: AppColors.isDark(context) ? 0.18 : 0.10,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accent color per notification type
// ─────────────────────────────────────────────────────────────────────────────

Color _accentForType(BuildContext context, String type) {
  final dark = AppColors.isDark(context);
  return switch (type) {
    'store_order' || 'order' =>
      dark ? const Color(0xFF90CDF4) : const Color(0xFF2563EB),
    'promotion' =>
      dark ? const Color(0xFFFFD166) : const Color(0xFFB7791F),
    'security' =>
      dark ? const Color(0xFFFCA5A5) : const Color(0xFFC53030),
    'system' =>
      dark ? const Color(0xFF67E8F9) : const Color(0xFF0E7490),
    _ => AppColors.accent(context),
  };
}
