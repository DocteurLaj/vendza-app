import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/session/liked_products_store.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/data/services/google_identity_service.dart';
import 'package:vendza/features/auth/presantation/pages/onbording_page.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';
import 'package:vendza/features/settings/presentation/pages/delete_account_page.dart';
import 'package:vendza/features/settings/presentation/pages/settings_detail_pages.dart';

import 'fakes/memory_secure_storage.dart';

class _TrackingAuthApi extends AuthApiService {
  _TrackingAuthApi(this.store) : super(tokenStore: store);

  final ApiTokenStore store;
  bool deleteCalled = false;
  String? lastConfirmation;
  String? lastPassword;

  @override
  Future<Map<String, dynamic>> deleteAccount({
    required String confirmation,
    String? password,
  }) async {
    deleteCalled = true;
    lastConfirmation = confirmation;
    lastPassword = password;
    if (confirmation != 'SUPPRIMER') {
      throw const ApiException(
        message: 'Confirmation invalide',
        statusCode: 422,
      );
    }
    return {
      'message': 'Compte supprime',
      'public_id': 'pid',
      'auth_mode': password == null ? 'google' : 'password',
      'orders_retained': 1,
      'stores_anonymized': 0,
    };
  }
}

class _FakeGoogle implements GoogleIdentityProvider {
  bool signedOut = false;

  @override
  Future<String?> authenticate() async => null;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  setUp(() {
    updateCurrentUser(
      UserModel(
        name: 'Ada Lovelace',
        lastname: 'Lovelace',
        firstname: 'Ada',
        address: 'London',
        email: 'ada@example.com',
        phoneNumber: '+100',
        urlimage: 'https://cdn.example/a.jpg',
      ),
    );
    likedProductIdsStore.value = <String>{'p1'};
    notificationStore.value = <NotificationModel>[
      NotificationModel(
        id: '1',
        name: 'Hello',
        description: 'Private',
        imageUrl: 'assets/images/profil.jpg',
        isRead: false,
      ),
    ];
    favoriteStores.clear();
  });

  test(
    'deleteAccount clears secure storage, user state and memory caches',
    () async {
      final store = ApiTokenStore(storage: MemorySecureStorage());
      await store.saveTokens(accessToken: 'a', refreshToken: 'r');
      final api = _TrackingAuthApi(store);
      final google = _FakeGoogle();
      var cleaned = false;
      final service = AuthSessionService(
        authApiService: api,
        googleIdentityProvider: google,
        tokenStore: store,
        catalogSynchronizer: (_) async {},
        sessionCleaner: () {
          cleaned = true;
          catalogRepository.clearUserData();
        },
      );

      final result = await service.deleteAccount(password: 'strong-password');

      expect(api.deleteCalled, isTrue);
      expect(api.lastConfirmation, 'SUPPRIMER');
      expect(api.lastPassword, 'strong-password');
      expect(store.hasAccessToken, isFalse);
      expect(cleaned, isTrue);
      expect(google.signedOut, isTrue);
      expect(currentUserStore.value.email, isEmpty);
      expect(currentUserStore.value.firstname, isEmpty);
      expect(likedProductIdsStore.value, isEmpty);
      expect(notificationStore.value, isEmpty);
      expect(result['orders_retained'], 1);
    },
  );

  testWidgets('incorrect confirmation is refused without calling API', (
    tester,
  ) async {
    final store = ApiTokenStore(storage: MemorySecureStorage());
    final api = _TrackingAuthApi(store);
    final service = AuthSessionService(
      authApiService: api,
      googleIdentityProvider: _FakeGoogle(),
      tokenStore: store,
      catalogSynchronizer: (_) async {},
      sessionCleaner: () {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DeleteAccountPage(sessionService: service, isGoogleOnly: false),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'DELETE');
    await tester.enterText(find.byType(TextField).at(1), 'strong-password');
    await tester.tap(find.byKey(const ValueKey('delete-account-confirm')));
    await tester.pump();

    expect(api.deleteCalled, isFalse);
    expect(
      find.text('Tapez SUPPRIMER pour confirmer la suppression.'),
      findsOneWidget,
    );
  });

  testWidgets('successful deletion resets navigation stack to onboarding', (
    tester,
  ) async {
    final store = ApiTokenStore(storage: MemorySecureStorage());
    await store.saveTokens(accessToken: 'a', refreshToken: 'r');
    final api = _TrackingAuthApi(store);
    final service = AuthSessionService(
      authApiService: api,
      googleIdentityProvider: _FakeGoogle(),
      tokenStore: store,
      catalogSynchronizer: (_) async {},
      sessionCleaner: catalogRepository.clearUserData,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DeleteAccountPage(sessionService: service, isGoogleOnly: true),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'SUPPRIMER');
    await tester.tap(find.byKey(const ValueKey('delete-account-confirm')));
    await tester.pumpAndSettle();

    expect(find.byType(OnbordingPage), findsOneWidget);
    expect(find.byType(DeleteAccountPage), findsNothing);
    expect(store.hasAccessToken, isFalse);
    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigatorState.canPop(), isFalse);
  });

  testWidgets('privacy settings expose delete-account entry point', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacySettingsPage()));
    expect(find.text('Supprimer mon compte'), findsOneWidget);

    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteAccountPage), findsOneWidget);
  });
}
