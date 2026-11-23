import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_api_service.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/notification/presantation/helpers/notification_presentation.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';
import 'package:vendza/features/order/presentation/pages/store_orders_page.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/presentation/pages/all_stores_page.dart';
import 'package:vendza/features/store/presentation/pages/my_store_product_page.dart';
import 'package:vendza/shared/utils/date_time_label.dart';
import 'package:vendza/shared/widgets/dialog/destructive_action_dialog.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';
import 'package:vendza/shared/widgets/media/context_image.dart';

enum _InboxFilter { all, purchases, stores, info }

_InboxFilter _contextFor(NotificationModel notification) =>
    switch (notification.name) {
      'order' => _InboxFilter.purchases,
      'store_order' ||
      'product_low_stock' ||
      'product_out_of_stock' => _InboxFilter.stores,
      _ => _InboxFilter.info,
    };

String _contextLabel(NotificationModel notification) =>
    switch (notification.name) {
      'order' => 'Achat',
      'store_order' => 'Vente',
      'product_low_stock' || 'product_out_of_stock' => 'Boutique',
      _ => 'Information Vendza',
    };

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, this.apiService});

  final NotificationApiService? apiService;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  _InboxFilter filter = _InboxFilter.all;

  ListStoreModel _store(NotificationModel n) => ListStoreModel(
    id: '${n.storeId}',
    name: n.storeName ?? 'Boutique',
    description: '',
    imageUrl: n.storeImage ?? n.imageUrl,
    rating: 0,
  );

  void _openDestination(NotificationModel n) {
    if (n.name == 'store_order' && n.storeId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              StoreOrdersPage(store: _store(n), initialOrderId: n.orderId),
        ),
      );
    } else if (n.name == 'order' && n.orderId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BuyerOrderDetailPage(orderId: n.orderId!),
        ),
      );
    } else if ((n.name == 'product_low_stock' ||
            n.name == 'product_out_of_stock') &&
        n.storeId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MyStoreProductPage(store: _store(n))),
      );
    }
  }

  Future<void> _openDetail(
    NotificationModel notification,
    List<NotificationModel> notifications,
  ) async {
    var thread = groupNotificationThreads(
      notifications,
    ).firstWhere((t) => t.id == notification.threadKey);
    var historyMayBeIncomplete = notifications.length >= 100;
    // The inbox endpoint provides only its 100 most recent alerts. For a
    // server-backed thread, fetch the complete history before presenting it.
    if (notifications.length >= 100 && notification.threadId != null) {
      try {
        final rows = await (widget.apiService ?? NotificationApiService())
            .notificationsForThread(thread.id);
        final messages = rows
            .map(notificationFromApi)
            .where((n) => n.threadKey == thread.id)
            .toList();
        if (!mounted) return;
        if (messages.isNotEmpty) {
          final byId = {
            for (final n in notificationStore.value) n.id: n,
            for (final n in messages) n.id: n,
          };
          notificationStore.value = byId.values.toList();
          thread = NotificationThreadModel(id: thread.id, messages: messages);
          historyMayBeIncomplete = false;
        }
      } on Object {
        // Keep the recent inbox available if the history request fails.
      }
    }
    if (!mounted) return;
    for (final message in thread.messages) {
      if (!message.isRead) markNotificationAsRead(message.id);
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationThreadPage(
          thread: thread,
          onOpenNotification: _openDestination,
          onDeleteNotification: _deleteMessage,
          onDeleteThread: () => _deleteThread(thread),
          historyMayBeIncomplete: historyMayBeIncomplete,
        ),
      ),
    );
  }

  Future<void> _deleteMessage(NotificationModel notification) async {
    final confirmed = await showDestructiveActionDialog(
      context: context,
      title: 'Supprimer cette notification ?',
      message: 'Cette notification sera masquée seulement pour votre compte.',
      details: ['Les autres utilisateurs gardent leur propre historique.'],
      confirmLabel: 'Supprimer la notification',
    );
    if (!confirmed || !mounted) return;
    final success = await deleteNotificationLocallyAndRemote(notification.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Notification supprimée pour vous.'
              : 'Suppression impossible. La notification a été restaurée.',
        ),
      ),
    );
  }

  Future<void> _deleteThread(NotificationThreadModel thread) async {
    final confirmed = await showDestructiveActionDialog(
      context: context,
      title: 'Supprimer cette conversation ?',
      message:
          'La conversation "${thread.title}" sera masquée seulement pour votre compte.',
      details: [
        '${thread.messageCount} notification${thread.messageCount > 1 ? 's' : ''} masquée${thread.messageCount > 1 ? 's' : ''} de votre boîte.',
        'Les autres utilisateurs gardent leur propre historique.',
      ],
      confirmLabel: 'Supprimer la conversation',
    );
    if (!confirmed || !mounted) return;
    final success = await deleteNotificationThreadLocallyAndRemote(thread.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Conversation supprimée pour vous.'
              : 'Suppression impossible. La conversation a été restaurée.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.appBackground(context),
    appBar: const VendzaPageHeader.root(
      title: 'Notifications',
      subtitle: 'Achats, boutiques et informations au même endroit',
      icon: Icons.notifications_none_rounded,
    ),
    body: SafeArea(
      top: false,
      child: ValueListenableBuilder<List<NotificationModel>>(
        valueListenable: notificationStore,
        builder: (context, notifications, _) {
          final filtered =
              notifications
                  .where(
                    (n) =>
                        filter == _InboxFilter.all || _contextFor(n) == filter,
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                          .compareTo(
                            a.createdAt ??
                                DateTime.fromMillisecondsSinceEpoch(0),
                          ),
                );
          final fresh = filtered.where((n) => !n.isRead).toList();
          final read = filtered.where((n) => n.isRead).toList();
          final count = unreadNotificationCount(notifications);
          final content = Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      count == 0
                          ? 'Aucune nouvelle alerte'
                          : '$count nouvelle${count > 1 ? 's' : ''} alerte${count > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Les plus récentes d’abord',
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final (choice, label) in [
                      (_InboxFilter.all, 'Tout'),
                      (_InboxFilter.purchases, 'Achats'),
                      (_InboxFilter.stores, 'Boutiques'),
                      (_InboxFilter.info, 'Infos'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: filter == choice,
                          onSelected: (_) => setState(() => filter = choice),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? const _EmptyNotificationState()
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune notification dans cette catégorie',
                          style: TextStyle(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        children: [
                          if (fresh.isNotEmpty) ...[
                            const _SectionTitle('Nouvelles'),
                            for (final n in fresh)
                              _NotificationTile(
                                notification: n,
                                onTap: () => _openDetail(n, notifications),
                                onDeleteThread: () => _deleteThread(
                                  groupNotificationThreads(
                                    notifications,
                                  ).firstWhere((t) => t.id == n.threadKey),
                                ),
                              ),
                          ],
                          if (read.isNotEmpty) ...[
                            const _SectionTitle('Déjà consultées'),
                            for (final n in read)
                              _NotificationTile(
                                notification: n,
                                onTap: () => _openDetail(n, notifications),
                                onDeleteThread: () => _deleteThread(
                                  groupNotificationThreads(
                                    notifications,
                                  ).firstWhere((t) => t.id == n.threadKey),
                                ),
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          );
          return ResponsiveContent(
            maxWidth: 720,
            child: MediaQuery.sizeOf(context).height < 500
                ? SingleChildScrollView(
                    child: SizedBox(height: 700, child: content),
                  )
                : content,
          );
        },
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
    child: Text(
      title,
      style: TextStyle(
        color: AppColors.textPrimary(context),
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDeleteThread,
  });
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDeleteThread;
  @override
  Widget build(BuildContext context) {
    final n = notification;
    final fg = AppColors.textPrimary(context);
    final muted = AppColors.textSecondary(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: n.isRead
                    ? AppColors.border(context)
                    : AppColors.accent(context).withValues(alpha: .3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VendzaContextImage(
                      imageUrl: n.storeImage ?? n.imageUrl,
                      icon: n.icon,
                      size: 38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!n.isRead)
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  '${_contextLabel(n)}${n.storeName == null ? '' : ' · ${n.storeName}'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (n.createdAt != null)
                                Text(
                                  vendzaDateTimeLabel(n.createdAt!),
                                  style: TextStyle(color: muted, fontSize: 10),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            n.displayTitle,
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            n.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.productName ?? n.categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ),
                    Text(
                      n.actionLabel ?? 'Lire',
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward, size: 13, color: fg),
                    PopupMenuButton<String>(
                      tooltip: 'Options de la conversation',
                      onSelected: (value) {
                        if (value == 'delete') onDeleteThread();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer la conversation'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A history of events, not a conversation: no reply composer or fabricated status.
class NotificationThreadPage extends StatelessWidget {
  const NotificationThreadPage({
    super.key,
    required this.thread,
    required this.onOpenNotification,
    required this.onDeleteNotification,
    required this.onDeleteThread,
    this.historyMayBeIncomplete = false,
  });
  final NotificationThreadModel thread;
  final ValueChanged<NotificationModel> onOpenNotification;
  final ValueChanged<NotificationModel> onDeleteNotification;
  final VoidCallback onDeleteThread;
  final bool historyMayBeIncomplete;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<NotificationModel>>(
    valueListenable: notificationStore,
    builder: (context, notifications, _) {
      final current = notifications
          .where((message) => message.threadKey == thread.id)
          .toList();
      if (current.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return const SizedBox.shrink();
      }
      final currentThread = NotificationThreadModel(
        id: thread.id,
        messages: current,
      );
      final messages = List<NotificationModel>.from(current)
        ..sort(
          (a, b) => (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      final latest = currentThread.latest;
      final fg = AppColors.textPrimary(context);
      final muted = AppColors.textSecondary(context);
      return Scaffold(
        backgroundColor: AppColors.appBackground(context),
        appBar: AppBar(
          backgroundColor: AppColors.card(context),
          foregroundColor: fg,
          title: Text(
            currentThread.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Options',
              onSelected: (value) {
                if (value == 'delete') onDeleteNotification(latest);
                if (value == 'thread') onDeleteThread();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'thread',
                  child: Text('Supprimer la conversation'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Supprimer cette notification'),
                ),
              ],
            ),
          ],
        ),
        body: ResponsiveContent(
          maxWidth: 720,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${_contextLabel(latest)}${latest.orderId == null ? '' : ' · Commande #${latest.orderId}'}',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                key: const Key('notification_summary_card'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent(context).withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent(context).withValues(alpha: .16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.displayTitle,
                      style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(latest.description, style: TextStyle(color: muted)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _SectionTitle('Historique des notifications'),
              if (historyMayBeIncomplete) ...[
                const SizedBox(height: 6),
                Text(
                  'Historique récent : des alertes plus anciennes peuvent manquer.',
                  style: TextStyle(color: AppColors.textSecondary(context)),
                ),
              ],
              for (final message in messages)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (message.createdAt != null)
                            Expanded(
                              child: Text(
                                vendzaDateTimeLabel(message.createdAt!),
                                style: TextStyle(color: muted, fontSize: 11),
                              ),
                            )
                          else
                            const Spacer(),
                          IconButton(
                            key: Key('delete_notification_${message.id}'),
                            tooltip: 'Supprimer cette notification',
                            icon: const Icon(Icons.delete_outline, size: 19),
                            onPressed: () => onDeleteNotification(message),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.displayTitle,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message.description,
                        style: TextStyle(color: muted, height: 1.4),
                      ),
                      if (message.actionLabel case final actionLabel?) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            key: Key('open_notification_${message.id}'),
                            onPressed: () => onOpenNotification(message),
                            child: Text('$actionLabel →'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (latest.actionLabel != null) ...[
                const SizedBox(height: 5),
                FilledButton(
                  onPressed: () => onOpenNotification(latest),
                  child: Text('${latest.actionLabel} →'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cette action ouvre la page concernée ; elle ne confirme rien automatiquement.',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 52,
                    color: AppColors.accent(context),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Aucune notification pour le moment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Les nouvelles de vos commandes et les messages des boutiques apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AllStoresPage()),
                    ),
                    child: const Text('Explorer les boutiques'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
