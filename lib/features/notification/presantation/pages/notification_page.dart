import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/notification/presantation/widgets/notification_tilter_toggle.dart';
import 'package:vendza/features/notification/presantation/widgets/notification_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool showUnread = true;
  final Set<String> _openedFromUnreadIds = {};

  void _handleFilterChanged(bool value) {
    if (value == showUnread) return;

    setState(() {
      showUnread = value;
      _openedFromUnreadIds.clear();
    });
  }

  void _markAsRead(String id) {
    if (showUnread) {
      setState(() {
        _openedFromUnreadIds.add(id);
      });
    }

    markNotificationAsRead(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBackground(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<List<NotificationModel>>(
          valueListenable: notificationStore,
          builder: (context, notifications, _) {
            final filtered = notifications.where((notification) {
              return showUnread
                  ? !notification.isRead ||
                        _openedFromUnreadIds.contains(notification.id)
                  : notification.isRead;
            }).toList();
            final unreadCount = unreadNotificationCount(notifications);

            return ResponsiveContent(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                    child: _NotificationHeader(unreadCount: unreadCount),
                  ),
                  NotificationFilterToggle(
                    showUnread: showUnread,
                    onChanged: _handleFilterChanged,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      reverseDuration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final position = Tween<Offset>(
                          begin: const Offset(0.04, 0.02),
                          end: Offset.zero,
                        ).animate(animation);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: position,
                            child: child,
                          ),
                        );
                      },
                      child: filtered.isEmpty
                          ? _EmptyNotificationState(
                              key: ValueKey("empty-$showUnread"),
                              showUnread: showUnread,
                            )
                          : ListView.separated(
                              key: ValueKey(
                                "list-$showUnread-${filtered.length}",
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return NotificationWidget(
                                  key: ValueKey(filtered[index].id),
                                  notification: filtered[index],
                                  onMarkAsRead: _markAsRead,
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              color: AppColors.accent(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Activité récente",
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  unreadCount == 0
                      ? "Toutes les notifications sont lues"
                      : "$unreadCount notification${unreadCount > 1 ? "s" : ""} non lue${unreadCount > 1 ? "s" : ""}",
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState({super.key, required this.showUnread});

  final bool showUnread;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.accent(context).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: AppColors.accent(context),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              showUnread
                  ? "Aucune notification non lue"
                  : "Aucune notification lue",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Les nouvelles activités apparaîtront ici.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
