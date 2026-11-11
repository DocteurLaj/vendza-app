import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';
import 'package:vendza/features/notification/presantation/pages/notification_page.dart';
import 'package:vendza/features/profil/presantation/pages/profile_page.dart';
import 'package:vendza/navigation/main_page.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';

void main() {
  testWidgets('navigation keeps notifications and exposes buyer orders', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await tester.pump();

    final bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bar.items.map((item) => item.label), [
      'Accueil',
      'Store',
      'Commandes',
      'Notifications',
    ]);
    expect(find.byTooltip('Ouvrir le profil'), findsOneWidget);

    await tester.tap(find.text('Commandes').last);
    await tester.pump();
    expect(find.byType(BuyerOrdersPage), findsOneWidget);
    expect(
      tester.widget<VendzaPageHeader>(find.byType(VendzaPageHeader)).showBack,
      isFalse,
    );
  });

  testWidgets(
    'profile opens from the home header and Store has no buyer orders',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainPage()));
      await tester.pump();
      await tester.tap(find.byTooltip('Ouvrir le profil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byTooltip('Retour'), findsOneWidget);

      await tester.tap(find.byTooltip('Retour'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byTooltip('Ouvrir le profil'), findsOneWidget);
    },
  );

  testWidgets('Store starts with owned boutiques and keeps favorites', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await tester.pump();
    await tester.tap(find.text('Store').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Mes commandes'), findsNothing);
    expect(find.text('Mes stores'), findsWidgets);
    expect(find.text('Mes favoris'), findsWidgets);
    expect(
      tester.getTopLeft(find.text('Mes stores').last).dy,
      lessThan(tester.getTopLeft(find.text('Mes favoris').last).dy),
    );
  });

  testWidgets('Notifications remains a reachable destination', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await tester.pump();
    await tester.tap(find.text('Notifications').last);
    await tester.pump();
    expect(find.byType(NotificationPage), findsOneWidget);
  });

  testWidgets('home header and four tabs fit a compact phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: MainPage()));
    await tester.pump();
    expect(find.byTooltip('Ouvrir le profil'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
