import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/core/upload/image_upload_controller.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/store_api_service.dart';
import 'package:vendza/features/store/data/services/store_customization_state.dart';
import 'package:vendza/features/store/presentation/pages/custom_page.dart';

class _RecordingStoreApi extends StoreApiService {
  final List<Map<String, Object?>> updates = [];

  @override
  Future<Map<String, dynamic>> updateStore({
    required int storeId,
    String? name,
    String? description,
    String? address,
    String? image,
    String? bannerUrl,
    String? whatsappUrl,
    String? instagramUrl,
    String? facebookUrl,
  }) async {
    updates.add({
      'storeId': storeId,
      'name': name,
      'description': description,
      'image': image,
      'bannerUrl': bannerUrl,
    });
    return {'idstore': storeId};
  }
}

Future<String> _fakeUpload(String path, {String purpose = 'catalog'}) async =>
    'https://cdn.vendza.test/uploaded.jpg';

void main() {
  tearDown(() {
    ownedStores.clear();
    stores.clear();
    clearSubscriptionSession();
    syncStoreCustomizationFromCatalog();
  });

  group('store banner mapping (#89)', () {
    test('listStoreFromApi maps bannerUrl separately from the logo', () {
      final withBanner = listStoreFromApi({
        'idstore': 5,
        'name': 'Shop',
        'image': 'https://cdn.vendza.test/logo.jpg',
        'bannerUrl': 'https://cdn.vendza.test/banner.jpg',
      });
      expect(withBanner.imageUrl, 'https://cdn.vendza.test/logo.jpg');
      expect(withBanner.bannerUrl, 'https://cdn.vendza.test/banner.jpg');

      final noImages = listStoreFromApi({'idstore': 6, 'name': 'Empty'});
      expect(noImages.bannerUrl, isEmpty);
      expect(isPlaceholderStoreImage(noImages.imageUrl), isTrue);
    });

    test('customization cover is the banner, never the logo/placeholder', () {
      final store = ListStoreModel(
        id: '5',
        name: 'Shop',
        description: '',
        imageUrl: 'assets/images/login_img.jpg',
        rating: 0,
      );
      final customization = customizationFromStore(store);
      expect(customization.coverImageUrl, isEmpty);
    });
  });

  group('StoreMediaSavePlan (#89)', () {
    test('untouched images are not sent and need no banner entitlement', () {
      final cover = ImageUploadController(
        initialUrl: 'https://cdn.vendza.test/banner.jpg',
      );
      final profile = ImageUploadController(
        initialUrl: 'https://cdn.vendza.test/logo.jpg',
      );
      final plan = StoreMediaSavePlan.fromControllers(
        cover: cover,
        profile: profile,
      );
      expect(plan.coverChanged, isFalse);
      expect(plan.profileChanged, isFalse);
      expect(plan.requiresBannerEntitlement, isFalse);
    });

    test(
      'a newly picked cover is dirty and requires the entitlement',
      () async {
        final cover = ImageUploadController(uploader: _fakeUpload);
        final profile = ImageUploadController(uploader: _fakeUpload);
        await cover.selectLocalImage('/tmp/new-cover.jpg');
        final plan = StoreMediaSavePlan.fromControllers(
          cover: cover,
          profile: profile,
        );
        expect(cover.isChanged, isTrue);
        expect(cover.remoteUrl, 'https://cdn.vendza.test/uploaded.jpg');
        expect(plan.coverChanged, isTrue);
        expect(plan.requiresBannerEntitlement, isTrue);
        expect(plan.profileChanged, isFalse);
      },
    );
  });

  testWidgets('free seller without logo can save a description change (#89)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = listStoreFromApi({
      'idstore': 12,
      'name': 'Boutique Gratuite',
      'description': 'Ancienne description',
    });
    ownedStores.add(store);
    syncStoreCustomizationFromCatalog();
    // No subscription context => free features (has_banner == false).
    clearSubscriptionSession();

    final api = _RecordingStoreApi();
    await tester.pumpWidget(
      MaterialApp(
        home: CustomPage(store: store, storeApiService: api),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Ancienne description'),
      'Nouvelle description',
    );
    await tester.ensureVisible(find.text('Enregistrer les changements'));
    await tester.tap(find.text('Enregistrer les changements'));
    await tester.pumpAndSettle();

    expect(find.textContaining('bannière'), findsNothing);
    expect(api.updates, hasLength(1));
    final update = api.updates.single;
    expect(update['description'], 'Nouvelle description');
    expect(update['bannerUrl'], isNull);
    expect(update['image'], isNull);
  });
}
