import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';
import 'package:vendza/features/order/presentation/pages/store_orders_page.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/notification/presantation/helpers/notification_presentation.dart';

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
  void _openNotification(NotificationModel notification) {
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
    for (final message in thread.messages) {
      if (!message.isRead) markNotificationAsRead(message.id);
    }
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
            final threads = groupNotificationThreads(notifications);
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
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      child: threads.isEmpty
                          ? _EmptyNotificationState(
                              key: const ValueKey('empty-notification-chats'),
                            )
                          : ListView.separated(
                              key: ValueKey('threads-${threads.length}'),
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
            final message = messages[index];
            final previous = index == 0 ? null : messages[index - 1];
            final showDate =
                previous == null ||
                !_sameDay(previous.createdAt, message.createdAt);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDate && message.createdAt != null)
                  _ChatDateDivider(date: message.createdAt!),
                _ChatMessageBubble(
                  notification: message,
                  onOpen: onOpenNotification,
                  onDelete: onDeleteNotification,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChatDateDivider extends StatelessWidget {
  const _ChatDateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Text(
          vendzaDateTimeLabel(date),
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.notification,
    required this.onOpen,
    required this.onDelete,
  });

  final NotificationModel notification;
  final ValueChanged<NotificationModel> onOpen;
  final ValueChanged<NotificationModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.displayTitle,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: AppColors.textSecondary(context),
                    ),
                    onSelected: (value) {
                      if (value == 'open') onOpen(notification);
                      if (value == 'delete') onDelete(notification);
                    },
                    itemBuilder: (context) => [
                      if (notification.actionLabel != null)
                        const PopupMenuItem(
                          value: 'open',
                          child: Text('Ouvrir'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                notification.description,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (notification.productName != null) ...[
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.textSecondary(context),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        notification.productName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (notification.createdAt != null)
                    Text(
                      vendzaDateTimeLabel(notification.createdAt!),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
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
                  if ((latest.productName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      latest.productName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (thread.unreadCount > 0)
                  _UnreadBubble(count: thread.unreadCount)
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary(context),
                  ),
                IconButton(
                  tooltip: 'Supprimer la conversation',
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textSecondary(context),
                    size: 19,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadBubble extends StatelessWidget {
  const _UnreadBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent(context),
        shape: count < 10 ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: count < 10 ? null : BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
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
  const _EmptyNotificationState({super.key});

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
              'Aucune conversation pour le moment',
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
