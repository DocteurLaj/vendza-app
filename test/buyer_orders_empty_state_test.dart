import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/home/presantation/pages/home.dart';
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';

class EmptyOrdersApi extends OrderApiService {
  int createCalls = 0;

  @override
  Future<List<OrderModel>> customerOrders({
    int page = 1,
    int pageSize = 20,
  }) async => [];

  @override
  Future<OrderModel> createOrder({
    required List<OrderItemRequest> items,
    required String idempotencyKey,
    required String contactPhone,
    required String deliveryAddress,
    String? customerNote,
  }) async {
    createCalls++;
    throw StateError('The empty-state action must not create an order');
  }
}

void main() {
  testWidgets(
    'empty orders keeps its CTA reachable on a short screen with large text',
    (tester) async {
      var explored = false;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: BuyerOrdersPage(
            inNavigation: true,
            api: EmptyOrdersApi(),
            onExploreProducts: () => explored = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(360, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final cta = find.text('Découvrir les produits');
      await tester.ensureVisible(cta);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getBottomRight(cta).dy, lessThanOrEqualTo(420));
      await tester.tap(cta);
      expect(explored, isTrue);
    },
  );

  testWidgets('empty root orders offers catalog and delegates tab switch', (
    tester,
  ) async {
    final api = EmptyOrdersApi();
    var homeSelected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return homeSelected
                ? const Scaffold(body: Text('Accueil catalogue'))
                : BuyerOrdersPage(
                    inNavigation: true,
                    api: api,
                    onExploreProducts: () =>
                        setState(() => homeSelected = true),
                  );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pas encore de commande'), findsOneWidget);
    expect(
      find.text(
        'Vos commandes apparaîtront ici. En attendant, découvrez les articles et les boutiques.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Découvrir les produits'));
    await tester.pumpAndSettle();
    expect(find.text('Accueil catalogue'), findsOneWidget);
    expect(api.createCalls, 0);
  });

  testWidgets('root tab without parent callback never stacks a home route', (
    tester,
  ) async {
    final api = EmptyOrdersApi();
    await tester.pumpWidget(
      MaterialApp(home: BuyerOrdersPage(inNavigation: true, api: api)),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Découvrir les produits'),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(HomePage), findsNothing);
    expect(api.createCalls, 0);
  });

  testWidgets('pushed orders opens actual catalog, not another MainPage', (
    tester,
  ) async {
    final api = EmptyOrdersApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BuyerOrdersPage(api: api),
                ),
              ),
              child: const Text('Ouvrir commandes'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir commandes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Découvrir les produits'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(api.createCalls, 0);
  });
}
