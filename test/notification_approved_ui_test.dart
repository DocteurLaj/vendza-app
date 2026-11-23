import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/notification/presantation/pages/notification_page.dart';

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
      expect(find.text('Texte 1'), findsOneWidget);
      expect(find.text('Texte 2'), findsOneWidget);
      expect(notificationStore.value.first.isRead, true);
      expect(notificationStore.value.last.isRead, false);
    },
  );
}
