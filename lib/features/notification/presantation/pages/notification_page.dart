import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';
import 'package:vendza/features/order/presentation/pages/store_orders_page.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/notification/presantation/helpers/notification_presentation.dart';
import 'package:vendza/features/notification/presantation/widgets/notification_tilter_toggle.dart';
import 'package:vendza/features/notification/presantation/widgets/notification_widget.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/utils/date_time_label.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/media/context_image.dart';

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

  void _openNotification(NotificationModel notification) {
    if (showUnread) setState(() => _openedFromUnreadIds.add(notification.id));
    markNotificationAsRead(notification.id);

    final storeId = notification.storeId;
    if (notification.name == 'store_order' && storeId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StoreOrdersPage(
            store: ListStoreModel(
              id: '$storeId',
              name: notification.storeName ?? 'Store',
              description: '',
              imageUrl: notification.storeImage ?? notification.imageUrl,
              rating: 0,
            ),
          ),
        ),
      );
      return;
    }

    if (notification.name == 'order' && notification.orderId != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const BuyerOrdersPage()));
    }
  }

  Future<void> _deleteThread(NotificationThreadModel thread) async {
    final confirmed = await _confirmDelete('Supprimer cette conversation ?');
    if (confirmed != true) return;
    await deleteNotificationThreadLocallyAndRemote(thread.id);
  }

  Future<void> _deleteMessage(NotificationModel notification) async {
    final confirmed = await _confirmDelete('Supprimer ce message ?');
    if (confirmed != true) return;
    await deleteNotificationLocallyAndRemote(notification.id);
  }

  Future<bool?> _confirmDelete(String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Cette suppression masque l’élément seulement pour votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _openThread(NotificationThreadModel thread) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationThreadPage(
          thread: thread,
          onOpenNotification: _openNotification,
          onDeleteNotification: _deleteMessage,
        ),
      ),
    );
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
          'Notifications',
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
            final threads = groupNotificationThreads(filtered);
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
                      child: threads.isEmpty
                          ? _EmptyNotificationState(
                              key: ValueKey('empty-$showUnread'),
                              showUnread: showUnread,
                            )
                          : ListView.separated(
                              key: ValueKey(
                                'threads-$showUnread-${threads.length}',
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
                              itemCount: threads.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final thread = threads[index];
                                return _NotificationThreadTile(
                                  thread: thread,
                                  onTap: () => _openThread(thread),
                                  onDelete: () => _deleteThread(thread),
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

class NotificationThreadPage extends StatelessWidget {
  const NotificationThreadPage({
    super.key,
    required this.thread,
    required this.onOpenNotification,
    required this.onDeleteNotification,
  });

  final NotificationThreadModel thread;
  final ValueChanged<NotificationModel> onOpenNotification;
  final ValueChanged<NotificationModel> onDeleteNotification;

  @override
  Widget build(BuildContext context) {
    final messages = List<NotificationModel>.from(thread.messages)
      ..sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });

    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBackground(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        title: Row(
          children: [
            VendzaContextImage(
              imageUrl: thread.imageUrl,
              icon: thread.latest.icon,
              size: 36,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                thread.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
      body: ResponsiveContent(
        maxWidth: 720,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          itemCount: messages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return NotificationWidget(
              notification: messages[index],
              onOpen: onOpenNotification,
              onDelete: onDeleteNotification,
            );
          },
        ),
      ),
    );
  }
}

class _NotificationThreadTile extends StatelessWidget {
  const _NotificationThreadTile({
    required this.thread,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationThreadModel thread;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final latest = thread.latest;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            VendzaContextImage(
              imageUrl: thread.imageUrl,
              icon: latest.icon,
              size: 52,
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
                          thread.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (latest.createdAt != null)
                        Text(
                          vendzaDateTimeLabel(latest.createdAt!),
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    latest.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (thread.unreadCount > 0)
                        _Pill(
                          threadUnreadText,
                          '${thread.unreadCount} nouveau${thread.unreadCount > 1 ? 'x' : ''}',
                        ),
                      _Pill('Messages', '${thread.messageCount}'),
                      if ((latest.productName ?? '').isNotEmpty)
                        _Pill('Produit', latest.productName!),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Supprimer la conversation',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String threadUnreadText = 'Nouveaux';

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: AppColors.accent(context),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
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
              Icons.mark_chat_unread_outlined,
              color: AppColors.accent(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversations notifications',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  unreadCount == 0
                      ? 'Toutes les conversations sont lues'
                      : '$unreadCount message${unreadCount > 1 ? 's' : ''} non lu${unreadCount > 1 ? 's' : ''}',
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
                  ? 'Aucune conversation non lue'
                  : 'Aucune conversation lue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les nouveaux messages de boutique, produit ou commande apparaîtront ici.',
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
