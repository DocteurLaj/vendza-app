import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_config.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/services/upload_api_service.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/profil/data/model/user_model.dart';
import 'package:vendza/features/profil/data/services/profile_api_service.dart';
import 'package:vendza/features/profil/presantation/widget/avatar_widget.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

import 'fakes/memory_secure_storage.dart';

class _FakeUploadApi extends UploadApiService {
  _FakeUploadApi({this.publicUrl, this.error});

  String? publicUrl;
  Object? error;
  String? lastPath;
  String? lastPurpose;

  @override
  Future<String> uploadLocalImage(
    String localPath, {
    String purpose = 'catalog',
  }) async {
    lastPath = localPath;
    lastPurpose = purpose;
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    return publicUrl!;
  }
}

UserModel _user({String avatar = ''}) {
  return UserModel(
    userId: 7,
    name: 'Ada Lovelace',
    lastname: 'Lovelace',
    firstname: 'Ada',
    address: '',
    email: 'ada@example.com',
    phoneNumber: '',
    urlimage: avatar,
  );
}

void main() {
  setUp(clearCurrentUser);

  test(
    'backend avatar response updates UserModel and currentUserStore',
    () async {
      const previous =
          'http://127.0.0.1:9000/vendza-images/users/ada/avatar/old.jpg';
      const next =
          'http://127.0.0.1:9000/vendza-images/users/ada/avatar/new.jpg';
      updateCurrentUser(_user(avatar: previous));

      final uploads = _FakeUploadApi(publicUrl: next);
      final tokenStore = ApiTokenStore(storage: MemorySecureStorage());
      await tokenStore.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      final client = ApiClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path.endsWith(ApiEndpoints.profileAvatar), isTrue);
          expect(request.body, contains(next));
          return http.Response(
            '{"message":"ok","avatar":"$next","avatarUrl":"$next"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
        tokenStore: tokenStore,
      );
      final service = ProfileApiService(client: client, uploadApi: uploads);

      final saved = await service.savePickedAvatar('/tmp/picked-avatar.jpg');
      applyCurrentUserAvatar(saved);

      expect(uploads.lastPurpose, 'avatar');
      expect(uploads.lastPath, '/tmp/picked-avatar.jpg');
      expect(saved, next);
      expect(currentUserStore.value.urlimage, next);
      expect(currentUserStore.value.hasRemoteAvatar, isTrue);
    },
  );

  test('avatar upload error keeps the previous avatar', () async {
    const previous =
        'http://127.0.0.1:9000/vendza-images/users/ada/avatar/old.jpg';
    updateCurrentUser(_user(avatar: previous));

    final uploads = _FakeUploadApi(
      error: const ApiException(message: 'Echec de l\'upload de l\'image.'),
    );
    final service = ProfileApiService(
      client: ApiClient(
        httpClient: MockClient((request) async {
          fail('profile API should not be called when upload fails');
        }),
      ),
      uploadApi: uploads,
    );

    await expectLater(
      service.savePickedAvatar('/tmp/picked-avatar.jpg'),
      throwsA(isA<ApiException>()),
    );
    expect(currentUserStore.value.urlimage, previous);
  });

  test('local paths are never stored as avatar URLs', () {
    updateCurrentUser(_user(avatar: '/storage/emulated/0/Download/pic.jpg'));
    expect(currentUserStore.value.hasRemoteAvatar, isFalse);

    applyCurrentUserAvatar('/data/user/0/app/cache/image.jpg');
    expect(currentUserStore.value.urlimage, isEmpty);

    applyCurrentUserAvatar('assets/images/profil.jpg');
    expect(currentUserStore.value.urlimage, isEmpty);
  });

  testWidgets('profile avatar shows initials without URL and image with URL', (
    tester,
  ) async {
    updateCurrentUser(_user());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvatarWidget(
            name: 'Ada Lovelace',
            email: 'ada@example.com',
            urlimage: '',
            editable: false,
          ),
        ),
      ),
    );

    expect(find.text('AL'), findsOneWidget);
    expect(find.byType(SmartImage), findsNothing);

    const url = 'http://127.0.0.1:9000/vendza-images/users/ada/avatar/new.jpg';
    updateCurrentUser(_user(avatar: url));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AvatarWidget(
            name: 'Ada Lovelace',
            email: 'ada@example.com',
            urlimage: url,
            editable: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SmartImage), findsOneWidget);
  });

  test('rewriteMediaUrl maps local MinIO hosts to the API loopback', () {
    final rewritten = ApiConfig.rewriteMediaUrl(
      'http://localhost:9000/vendza-images/users/ada/avatar/one.jpg',
    );
    expect(rewritten, contains(Uri.parse(ApiConfig.defaultBaseUrl).host));
    expect(rewritten, contains(':9000/vendza-images/users/ada/avatar/one.jpg'));
    expect(
      ApiConfig.rewriteMediaUrl(
        'http://127.0.0.1:9000/vendza-images/users/ada/avatar/one.jpg',
      ),
      'http://127.0.0.1:9000/vendza-images/users/ada/avatar/one.jpg',
    );
  });
}
