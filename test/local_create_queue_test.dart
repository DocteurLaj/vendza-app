import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/upload_api_service.dart';
import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/core/sync/local_create_queue.dart';

void main() {
  test('local entity ids are namespaced', () {
    final id = newLocalEntityId('store');
    expect(isLocalEntityId(id), isTrue);
    expect(isLocalEntityId('42'), isFalse);
  });

  test('sync labels match the owner catalog copy', () {
    expect(EntitySyncStatus.queued.label, 'Envoi vers le serveur…');
    expect(EntitySyncStatus.syncing.label, 'Envoi vers le serveur…');
    expect(EntitySyncStatus.online.label, 'En ligne');
    expect(EntitySyncStatus.error.label, 'Échec de synchronisation');
  });

  test('local create operations survive json roundtrip', () {
    final op = LocalCreateOp(
      id: 'local-store-1',
      kind: LocalCreateKind.store,
      payload: {'name': 'Zira', 'imagePath': '/tmp/logo.jpg'},
      userId: 7,
      createRequestSent: true,
    );

    final restored = LocalCreateOp.fromJson(op.toJson());
    expect(restored.id, 'local-store-1');
    expect(restored.kind, LocalCreateKind.store);
    expect(restored.payload['name'], 'Zira');
    expect(restored.userId, 7);
    expect(restored.createRequestSent, isTrue);
    expect(restored.entityStatus, EntitySyncStatus.queued);
  });

  test('remote image urls skip a second upload', () async {
    final url = 'https://cdn.vendza.test/store.jpg';
    expect(isRemoteMediaUrl(url), isTrue);
    expect(isRemoteMediaUrl('/data/user/0/logo.jpg'), isFalse);
    expect(
      await UploadApiService().uploadLocalImage(url),
      url,
    );
  });

  test('missing local image is not treated as a network outage', () {
    expect(
      isNetworkFailure(
        const ApiException(message: 'Image locale introuvable.'),
      ),
      isFalse,
    );
    expect(
      isNetworkFailure(const ApiException(message: 'La requete a expire.', statusCode: 408)),
      isTrue,
    );
  });

  test('syncing bar uses real progress and shows a percent label', () {
    expect(EntitySyncStatus.syncing.barValue(0.42), closeTo(0.42, 0.001));
    expect(EntitySyncStatus.queued.barValue(0.08), isNull);
    expect(
      EntitySyncStatus.syncing.labelWithProgress(0.42),
      'Envoi vers le serveur… 42%',
    );
  });
}
