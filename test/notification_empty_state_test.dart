import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/notification/presantation/pages/notification_page.dart';
import 'package:vendza/features/store/presentation/pages/all_stores_page.dart';
import 'package:vendza/features/store/presentation/pages/my_store_page.dart';

void main() {
  testWidgets(
    'empty inbox keeps exploration reachable on a short screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const NotificationPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final cta = find.text('Explorer les boutiques');
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getBottomRight(cta).dy, lessThanOrEqualTo(420));
      await tester.tap(cta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AllStoresPage), findsOneWidget);
    },
  );

  late List<NotificationModel> originalNotifications;

  setUp(() {
    originalNotifications = notificationStore.value;
    notificationStore.value = <NotificationModel>[];
  });

  tearDown(() {
    notificationStore.value = originalNotifications;
  });

  testWidgets(
    'empty inbox shows the approved notification copy, not the read status',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
      await tester.pump();

      expect(find.text('Aucune notification pour le moment'), findsOneWidget);
      expect(
        find.text(
          'Les nouvelles de vos commandes et les messages des boutiques apparaîtront ici.',
        ),
        findsOneWidget,
      );
      expect(find.text('Explorer les boutiques'), findsOneWidget);
      expect(find.text('Toutes les conversations sont lues'), findsNothing);
      expect(find.text('Aucune conversation pour le moment'), findsNothing);
    },
  );

  testWidgets('empty inbox exploration opens the public store catalog', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
    await tester.pump();

    await tester.tap(find.text('Explorer les boutiques'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AllStoresPage), findsOneWidget);
    expect(find.byType(MyStorePage), findsNothing);
  });

  testWidgets('existing read conversation keeps its read status and thread', (
    tester,
  ) async {
    notificationStore.value = [
      NotificationModel(
        id: 'test-read-message',
        name: 'message',
        description: 'Message déjà lu',
        imageUrl: '',
        isRead: true,
      ),
    ];
    await tester.pumpWidget(const MaterialApp(home: NotificationPage()));
    await tester.pump();

    expect(find.text('Aucune nouvelle alerte'), findsOneWidget);
    expect(find.text('Aucune notification pour le moment'), findsNothing);
    expect(find.text('Explorer les boutiques'), findsNothing);
  });
}
