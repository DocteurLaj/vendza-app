import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_api_service.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/notification/presantation/pages/notification_page.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';

NotificationModel alert(
  String id,
  String name,
  bool read, {
  String? thread,
  int? storeId,
  int? orderId,
}) => NotificationModel(
  id: id,
  name: name,
  title: 'Alerte $id',
  description: 'Texte $id',
  imageUrl: '',
  isRead: read,
  threadId: thread,
  storeId: storeId,
  orderId: orderId,
  storeName: storeId == null ? null : 'Boutique $storeId',
  createdAt: DateTime(2026, 10, 20, int.parse(id)),
);

class _FullThreadApi extends NotificationApiService {
  @override
  Future<List<Map<String, dynamic>>> notificationsForThread(
    String threadId,
  ) async {
    if (threadId != 'shared') throw StateError('wrong thread');
    return [
      {
        'idnotification': 101,
        'type': 'store_order',
        'title': 'Ancien événement',
        'content': 'Texte historique',
        'seen': true,
        'thread_id': 'shared',
        'store_idstore': 7,
        'createdAt': '2026-01-01T00:00:00Z',
      },
      {
        'idnotification': 999,
        'type': 'store_order',
        'title': 'Nouvel événement',
        'content': 'Texte 999',
        'seen': false,
        'thread_id': 'shared',
        'store_idstore': 7,
        'createdAt': '2026-12-01T00:00:00Z',
      },
    ];
  }
}

class _FailingThreadApi extends NotificationApiService {
  @override
  Future<List<Map<String, dynamic>>> notificationsForThread(String threadId) {
    throw StateError('history unavailable');
  }
}

void main() {
  setUp(() => notificationStore.value = []);
  tearDown(() => notificationStore.value = []);

  testWidgets('opening inbox preserves unread and separates new from read', (
    tester,
  ) async {
    notificationStore.value = [
      alert('1', 'store_order', false, storeId: 7, orderId: 12),
      alert('2', 'general', true),
    ];
    await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
    await tester.pump();
    expect(notificationStore.value.first.isRead, false);
    expect(find.text('Nouvelles'), findsOneWidget);
    expect(find.text('Déjà consultées'), findsOneWidget);
    expect(find.text('1 nouvelle alerte'), findsOneWidget);
    expect(find.text('Voir la commande'), findsOneWidget);
  });

  testWidgets(
    'filters separate purchases, stores and information without changing read state',
    (tester) async {
      notificationStore.value = [
        alert('1', 'order', false, orderId: 1),
        alert('2', 'store_order', false, storeId: 7, orderId: 2),
        alert('3', 'general', true),
      ];
      await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
      await tester.pump();
      await tester.tap(find.text('Achats'));
      await tester.pumpAndSettle();
      expect(find.text('Texte 1'), findsOneWidget);
      expect(find.text('Texte 2'), findsNothing);
      await tester.tap(find.text('Boutiques'));
      await tester.pumpAndSettle();
      expect(find.text('Texte 2'), findsOneWidget);
      expect(find.text('Texte 1'), findsNothing);
      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();
      expect(find.text('Texte 3'), findsOneWidget);
      expect(notificationStore.value.where((n) => !n.isRead).length, 2);
    },
  );

  testWidgets(
    'grouped alerts keep conversation and individual deletion actions',
    (tester) async {
      notificationStore.value = [
        alert(
          '1',
          'store_order',
          false,
          thread: 'order:12',
          storeId: 7,
          orderId: 12,
        ),
        alert(
          '2',
          'store_order',
          true,
          thread: 'order:12',
          storeId: 7,
          orderId: 12,
        ),
      ];
      await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
      await tester.pump();
      expect(find.byTooltip('Options de la conversation'), findsWidgets);
      await tester.tap(find.text('Texte 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byTooltip('Options'), findsOneWidget);
      await tester.tap(find.byTooltip('Options'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer la conversation'), findsOneWidget);
      expect(find.text('Supprimer cette notification'), findsOneWidget);
    },
  );

  testWidgets(
    'opening a notification shows chronological thread and marks only that thread read',
    (tester) async {
      notificationStore.value = [
        alert(
          '1',
          'store_order',
          false,
          thread: 'order:12',
          storeId: 7,
          orderId: 12,
        ),
        alert(
          '2',
          'store_order',
          true,
          thread: 'order:12',
          storeId: 7,
          orderId: 12,
        ),
        alert('3', 'general', false),
      ];
      await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
      await tester.pump();
      await tester.tap(find.text('Texte 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(NotificationThreadPage), findsOneWidget);
      expect(find.text('Historique des notifications'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(NotificationThreadPage),
          matching: find.text('Texte 1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(NotificationThreadPage),
          matching: find.text('Texte 2'),
        ),
        findsNWidgets(2),
      );
      expect(notificationStore.value.first.isRead, true);
      expect(notificationStore.value.last.isRead, false);
    },
  );

  testWidgets('alert detail summarizes its latest real event before history', (
    tester,
  ) async {
    notificationStore.value = [
      alert('1', 'store_order', false, storeId: 7, orderId: 12),
    ];
    await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
    await tester.pump();
    await tester.tap(find.text('Texte 1'));
    await tester.pumpAndSettle();
    final summary = find.byKey(const Key('notification_summary_card'));
    expect(summary, findsOneWidget);
    expect(
      find.descendant(of: summary, matching: find.text('Texte 1')),
      findsOneWidget,
    );
  });

  testWidgets(
    'delete action targets a selected history entry and refreshes detail',
    (tester) async {
      final first = alert(
        '1',
        'store_order',
        true,
        thread: 'order:12',
        storeId: 7,
      );
      final second = alert(
        '2',
        'store_order',
        true,
        thread: 'order:12',
        storeId: 7,
      );
      notificationStore.value = [first, second];
      String? deletedId;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationThreadPage(
            thread: groupNotificationThreads(notificationStore.value).single,
            onOpenNotification: (_) {},
            onDeleteNotification: (event) {
              deletedId = event.id;
              notificationStore.value = notificationStore.value
                  .where((n) => n.id != event.id)
                  .toList();
            },
            onDeleteThread: () {},
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('delete_notification_1')));
      await tester.pumpAndSettle();
      expect(deletedId, '1');
      expect(find.text('Texte 1'), findsNothing);
      expect(find.text('Texte 2'), findsWidgets);
    },
  );

  testWidgets('detail loads older events beyond the recent inbox page', (
    tester,
  ) async {
    notificationStore.value = [
      alert('999', 'store_order', false, thread: 'shared', storeId: 7),
      for (var i = 1; i < 100; i++)
        alert('$i', 'general', true, thread: 'other-$i'),
    ];
    await tester.pumpWidget(
      MaterialApp(home: NotificationPage(apiService: _FullThreadApi())),
    );
    await tester.pump();
    await tester.tap(find.text('Texte 999'));
    await tester.pumpAndSettle();
    expect(find.text('Texte historique'), findsOneWidget);
  });

  testWidgets('partial history is identified when the thread endpoint fails', (
    tester,
  ) async {
    notificationStore.value = [
      alert('999', 'store_order', false, thread: 'shared', storeId: 7),
      for (var i = 1; i < 100; i++)
        alert('$i', 'general', true, thread: 'other-$i'),
    ];
    await tester.pumpWidget(
      MaterialApp(home: NotificationPage(apiService: _FailingThreadApi())),
    );
    await tester.pump();
    await tester.tap(find.text('Texte 999'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Historique récent : des alertes plus anciennes peuvent manquer.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('history action preserves the specific event context', (
    tester,
  ) async {
    notificationStore.value = [
      alert(
        '1',
        'store_order',
        true,
        thread: 'shared',
        storeId: 7,
        orderId: 12,
      ),
      alert('2', 'general', true, thread: 'shared'),
    ];
    String? openedId;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationThreadPage(
          thread: groupNotificationThreads(notificationStore.value).single,
          onOpenNotification: (n) => openedId = n.id,
          onDeleteNotification: (_) {},
          onDeleteThread: () {},
        ),
      ),
    );
    await tester.ensureVisible(find.text('Texte 1'));
    await tester.tap(find.byKey(const Key('open_notification_1')));
    expect(openedId, '1');
  });

  testWidgets('removing the final event returns to the inbox once', (
    tester,
  ) async {
    notificationStore.value = [alert('1', 'general', true)];
    final thread = groupNotificationThreads(notificationStore.value).single;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NotificationThreadPage(
                    thread: thread,
                    onOpenNotification: (_) {},
                    onDeleteNotification: (_) => notificationStore.value = [],
                    onDeleteThread: () {},
                  ),
                ),
              ),
              child: const Text('Ouvrir le détail'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir le détail'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_notification_1')));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationThreadPage), findsNothing);
    expect(find.text('Ouvrir le détail'), findsOneWidget);
  });

  testWidgets('purchase alert opens the exact buyer order detail', (
    tester,
  ) async {
    notificationStore.value = [alert('1', 'order', false, orderId: 2481)];
    await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
    await tester.pump();
    await tester.tap(find.text('Texte 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivre la commande →').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BuyerOrderDetailPage), findsOneWidget);
    expect(
      tester
          .widget<BuyerOrderDetailPage>(find.byType(BuyerOrderDetailPage))
          .orderId,
      2481,
    );
  });
}
