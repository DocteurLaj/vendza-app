import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as home;
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_api_service.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/dialog/destructive_action_dialog.dart';

class _FailingNotificationApiService extends NotificationApiService {
  @override
  Future<Map<String, dynamic>> deleteThread(String threadId) {
    throw Exception('network down');
  }
}

class _SuccessfulNotificationApiService extends NotificationApiService {
  String? deletedThreadId;

  @override
  Future<Map<String, dynamic>> deleteThread(String threadId) async {
    deletedThreadId = threadId;
    return {'deleted': true};
  }
}

ListStoreModel _store(String id, String name) {
  return ListStoreModel(
    id: id,
    name: name,
    description: 'Description $name',
    imageUrl: 'https://example.com/$id.png',
    rating: 4.5,
  );
}

ProductModel _product(String id, String storeId) {
  return ProductModel(
    id: id,
    storeId: storeId,
    name: 'Product $id',
    imageurl: '',
    price: '10',
    status: 'available',
    category: 'Test',
  );
}

NotificationModel _notification(String id, String threadId) {
  return NotificationModel(
    id: id,
    name: 'message',
    title: 'Message $id',
    description: 'Contenu message $id',
    imageUrl: '',
    isRead: false,
    threadId: threadId,
    threadType: 'chat',
  );
}

void main() {
  setUp(() {
    stores.clear();
    ownedStores.clear();
    favoriteStores.clear();
    products.clear();
    homeStores.clear();
    homeProducts.clear();
    notificationStore.value = <NotificationModel>[];
  });

  test(
    'removeDeletedStoreFromCatalog removes the store and its local products immediately',
    () {
      final deleted = _store('7', 'Boutique Laj');
      final kept = _store('8', 'Autre boutique');
      stores.addAll([deleted, kept]);
      ownedStores.addAll([deleted, kept]);
      homeStores.addAll([
        home.StoreModel(
          id: '7',
          name: 'Boutique Laj',
          image: '',
          description: '',
        ),
        home.StoreModel(
          id: '8',
          name: 'Autre boutique',
          image: '',
          description: '',
        ),
      ]);
      products.addAll([_product('70', '7'), _product('80', '8')]);
      homeProducts.addAll([_product('71', '7'), _product('81', '8')]);

      removeDeletedStoreFromCatalog('7');

      expect(ownedStores.map((store) => store.id), ['8']);
      expect(stores.map((store) => store.id), ['8']);
      expect(homeStores.map((store) => store.id), ['8']);
      expect(products.map((product) => product.storeId), ['8']);
      expect(homeProducts.map((product) => product.storeId), ['8']);
    },
  );

  testWidgets('destructive dialog requires the exact confirmation phrase', (
    tester,
  ) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              confirmed = await showDestructiveActionDialog(
                context: context,
                title: 'Supprimer Boutique Laj ?',
                message: 'Cette boutique sera masquée au public.',
                details: const [
                  'Produits masqués publiquement',
                  'Commandes existantes conservées',
                ],
                confirmPhrase: 'SUPPRIMER',
                confirmLabel: 'Supprimer définitivement',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer Boutique Laj ?'), findsOneWidget);
    expect(find.text('Produits masqués publiquement'), findsOneWidget);
    final deleteButton = find.widgetWithText(
      FilledButton,
      'Supprimer définitivement',
    );
    expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'supprimer');
    await tester.pump();
    expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'SUPPRIMER');
    await tester.pump();
    expect(tester.widget<FilledButton>(deleteButton).onPressed, isNotNull);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  test(
    'deleteNotificationThreadLocallyAndRemote removes a thread and calls the API',
    () async {
      final api = _SuccessfulNotificationApiService();
      notificationStore.value = [
        _notification('1', 'thread-a'),
        _notification('2', 'thread-a'),
        _notification('3', 'thread-b'),
      ];

      await deleteNotificationThreadLocallyAndRemote('thread-a', api: api);

      expect(api.deletedThreadId, 'thread-a');
      expect(notificationStore.value.map((notification) => notification.id), [
        '3',
      ]);
    },
  );

  test(
    'deleteNotificationThreadLocallyAndRemote restores the thread when API fails',
    () async {
      notificationStore.value = [
        _notification('1', 'thread-a'),
        _notification('2', 'thread-a'),
        _notification('3', 'thread-b'),
      ];

      await deleteNotificationThreadLocallyAndRemote(
        'thread-a',
        api: _FailingNotificationApiService(),
      );

      expect(notificationStore.value.map((notification) => notification.id), [
        '1',
        '2',
        '3',
      ]);
    },
  );
}
