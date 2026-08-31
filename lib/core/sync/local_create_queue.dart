import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/services/upload_api_service.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/core/sync/local_create_queue_storage.dart';
import 'package:vendza/features/auth/data/services/auth_api_service.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/product_api_service.dart';
import 'package:vendza/features/store/data/services/store_api_service.dart';
import 'package:vendza/shared/models/product_model.dart';

enum LocalCreateKind { store, product, productUpdate }

enum LocalCreatePhase {
  queued,
  uploading,
  creating,
  waitingNetwork,
  failed,
  completed,
}

String newLocalEntityId(String kind) {
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final noise = Random().nextInt(1 << 32).toRadixString(16);
  return 'local-$kind-$stamp-$noise';
}

class LocalCreateOp {
  LocalCreateOp({
    required this.id,
    required this.kind,
    required this.payload,
    this.dependsOnId,
    this.userId,
    this.status = LocalCreatePhase.queued,
    this.progress = 0.08,
    this.errorMessage,
    this.serverId,
    this.createRequestSent = false,
  });

  final String id;
  final LocalCreateKind kind;
  Map<String, dynamic> payload;
  final String? dependsOnId;
  final int? userId;
  LocalCreatePhase status;
  double progress;
  String? errorMessage;
  String? serverId;
  bool createRequestSent;

  bool get isOpen => status != LocalCreatePhase.completed;

  EntitySyncStatus get entityStatus => switch (status) {
    LocalCreatePhase.queued => EntitySyncStatus.queued,
    LocalCreatePhase.uploading || LocalCreatePhase.creating =>
      EntitySyncStatus.syncing,
    LocalCreatePhase.waitingNetwork => EntitySyncStatus.waitingNetwork,
    LocalCreatePhase.failed => EntitySyncStatus.error,
    LocalCreatePhase.completed => EntitySyncStatus.online,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'payload': payload,
    'dependsOnId': dependsOnId,
    'userId': userId,
    'status': status.name,
    'progress': progress,
    'errorMessage': errorMessage,
    'serverId': serverId,
    'createRequestSent': createRequestSent,
  };

  factory LocalCreateOp.fromJson(Map<String, dynamic> json) {
    return LocalCreateOp(
      id: json['id'] as String,
      kind: LocalCreateKind.values.byName(json['kind'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      dependsOnId: json['dependsOnId'] as String?,
      userId: json['userId'] as int?,
      status: LocalCreatePhase.values.byName(
        json['status'] as String? ?? 'queued',
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.08,
      errorMessage: json['errorMessage'] as String?,
      serverId: json['serverId'] as String?,
      createRequestSent: json['createRequestSent'] == true,
    );
  }
}

class LocalCreateQueue {
  LocalCreateQueue({
    required UploadApiService uploads,
    required StoreApiService stores,
    required ProductApiService products,
    required AuthApiService auth,
    required void Function() onChanged,
    required ListStoreModel Function(Map<String, dynamic> json) storeFromApi,
  }) : _uploads = uploads,
       _stores = stores,
       _productApi = products,
       _auth = auth,
       _onChanged = onChanged,
       _storeFromApi = storeFromApi;

  final UploadApiService _uploads;
  final StoreApiService _stores;
  final ProductApiService _productApi;
  final AuthApiService _auth;
  final void Function() _onChanged;
  final ListStoreModel Function(Map<String, dynamic> json) _storeFromApi;

  final List<LocalCreateOp> _ops = [];
  bool _busy = false;
  bool _wakeQueued = false;
  bool _started = false;
  DateTime? _lastProgressPush;
  List<ListStoreModel> _ownedStores = [];
  List<ProductModel> _products = [];
  List<ListStoreModel> _publicStores = [];
  List<ProductModel> _homeProducts = [];

  List<LocalCreateOp> get operations => List.unmodifiable(_ops);

  void attachCatalog({
    required List<ListStoreModel> ownedStores,
    required List<ProductModel> products,
    required List<ListStoreModel> publicStores,
    required List<ProductModel> homeProducts,
  }) {
    _ownedStores = ownedStores;
    _products = products;
    _publicStores = publicStores;
    _homeProducts = homeProducts;
  }

  LocalCreateOp? opFor(String id) {
    for (final op in _ops) {
      if (op.id == id || op.serverId == id) return op;
    }
    return null;
  }

  Future<void> start() async {
    if (!_started) {
      _started = true;
      await load();
      NetworkStatus.isOffline.addListener(_onNetworkChanged);
    }
    unawaited(process());
  }

  void dispose() {
    NetworkStatus.isOffline.removeListener(_onNetworkChanged);
  }

  void _onNetworkChanged() {
    if (!NetworkStatus.isOffline.value) {
      process();
    }
  }

  Future<void> load() async {
    try {
      final raw = await readLocalCreateQueueJson();
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _ops
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
            (item) => LocalCreateOp.fromJson(Map<String, dynamic>.from(item)),
          ),
        );
    } on Object {
      // A corrupt queue must not block catalog bootstrap.
    }
  }

  Future<void> persist() async {
    try {
      await writeLocalCreateQueueJson(
        jsonEncode(_ops.map((op) => op.toJson()).toList()),
      );
    } on Object {
      // Persistence is best-effort; in-memory queue still works this session.
    }
  }

  List<LocalCreateOp> _opsForCurrentUser() {
    final userId = currentUserStore.value.userId;
    return _ops.where((op) {
      if (!op.isOpen) return false;
      if (op.userId == null || userId == null) return true;
      return op.userId == userId;
    }).toList();
  }

  Future<ListStoreModel> enqueueStore({
    required String name,
    required String description,
    required String address,
    required String imagePath,
    String? bannerPath,
    String? whatsappUrl,
    String? instagramUrl,
    String? facebookUrl,
  }) async {
    final id = newLocalEntityId('store');
    final op = LocalCreateOp(
      id: id,
      kind: LocalCreateKind.store,
      userId: currentUserStore.value.userId,
      payload: {
        'name': name,
        'description': description,
        'address': address,
        'imagePath': imagePath,
        'bannerPath': bannerPath,
        'whatsappUrl': whatsappUrl,
        'instagramUrl': instagramUrl,
        'facebookUrl': facebookUrl,
      },
    );
    _ops.add(op);
    final store = storeFromOp(op);
    _ownedStores.insert(0, store);
    await persist();
    _onChanged();
    process();
    return store;
  }

  Future<ProductModel> enqueueProduct({
    required String storeId,
    required String storeName,
    required String title,
    required String description,
    required String price,
    required double numericPrice,
    required String imagePath,
    String category = '',
    Map<String, dynamic>? variation,
  }) async {
    final dependsOn = isLocalEntityId(storeId) ? storeId : null;
    final id = newLocalEntityId('product');
    final op = LocalCreateOp(
      id: id,
      kind: LocalCreateKind.product,
      dependsOnId: dependsOn,
      userId: currentUserStore.value.userId,
      payload: {
        'storeId': storeId,
        'storeName': storeName,
        'title': title,
        'description': description,
        'price': price,
        'numericPrice': numericPrice,
        'stock': 1,
        'imagePath': imagePath,
        'category': category,
        'variation': variation,
      },
    );
    _ops.add(op);
    final product = productFromOp(op);
    _products.insert(0, product);
    await persist();
    _onChanged();
    process();
    return product;
  }

  Future<ProductModel> enqueueProductUpdate(ProductModel product) async {
    _ops.removeWhere(
      (op) =>
          op.kind == LocalCreateKind.productUpdate &&
          (op.id == product.id ||
              op.payload['productId'] == product.id ||
              (product.localId.isNotEmpty && op.id == product.localId)),
    );
    final pending = product.copyWith(
      syncStatus: EntitySyncStatus.syncing,
      syncProgress: 0.08,
    );
    final op = LocalCreateOp(
      id: product.id,
      kind: LocalCreateKind.productUpdate,
      userId: currentUserStore.value.userId,
      payload: _productUpdatePayload(pending),
    );
    _ops.add(op);
    _replaceProduct(pending);
    await persist();
    _onChanged();
    process();
    return pending;
  }

  Future<void> retry(String id) async {
    final op = opFor(id);
    if (op == null) return;
    if (op.status != LocalCreatePhase.failed &&
        op.status != LocalCreatePhase.waitingNetwork) {
      return;
    }
    op.status = LocalCreatePhase.queued;
    op.errorMessage = null;
    op.progress = 0.08;
    await persist();
    _onChanged();
    await process();
  }

  Future<void> discard(String id) async {
    _ops.removeWhere((op) => op.id == id || op.dependsOnId == id);
    await persist();
    _onChanged();
  }

  Future<void> updateProductPayload(ProductModel product) async {
    final op = opFor(product.id);
    if (op == null || op.kind != LocalCreateKind.product) return;
    op.payload['title'] = product.name;
    op.payload['description'] = product.description;
    op.payload['price'] = product.price;
    op.payload['imagePath'] = product.imageurl;
    op.payload['category'] = product.category;
    op.payload['isActive'] = product.isActive;
    op.payload['variation'] = _variationMap(product.variants);
    op.payload['variants'] = product.variants.map(_variantToJson).toList();
    await persist();
  }

  ListStoreModel storeFromOp(LocalCreateOp op) {
    final payload = op.payload;
    return ListStoreModel(
      id: op.serverId ?? op.id,
      localId: op.id,
      name: payload['name'] as String? ?? '',
      description: payload['description'] as String? ?? '',
      imageUrl: payload['imagePath'] as String? ?? '',
      rating: 0,
      city: payload['address'] as String? ?? '',
      whatsappUrl: payload['whatsappUrl'] as String? ?? '',
      instagramUrl: payload['instagramUrl'] as String? ?? '',
      facebookUrl: payload['facebookUrl'] as String? ?? '',
      syncStatus: op.entityStatus,
      syncProgress: op.progress,
      syncError: op.errorMessage,
    );
  }

  ProductModel productFromOp(LocalCreateOp op) {
    final payload = op.payload;
    return ProductModel(
      id: op.serverId ?? op.id,
      localId: op.id,
      name: payload['title'] as String? ?? '',
      price: payload['price'] as String? ?? '',
      imageurl: payload['imagePath'] as String? ?? '',
      status: '',
      description: payload['description'] as String? ?? '',
      category: payload['category'] as String? ?? '',
      storeId: payload['storeId'] as String? ?? '',
      storeName: payload['storeName'] as String? ?? '',
      syncStatus: op.entityStatus,
      syncProgress: op.progress,
      syncError: op.errorMessage,
    );
  }

  void rehydrate({
    required List<ListStoreModel> ownedStores,
    required List<ProductModel> products,
  }) {
    for (final op in _opsForCurrentUser()) {
      if (op.kind == LocalCreateKind.store) {
        final store = storeFromOp(op);
        final index = ownedStores.indexWhere(
          (item) =>
              item.id == store.id ||
              item.localId == op.id ||
              item.id == op.id,
        );
        if (index >= 0) {
          ownedStores[index] = store;
        } else {
          ownedStores.insert(0, store);
        }
      } else if (op.kind == LocalCreateKind.productUpdate) {
        _overlayProductUpdate(op, products);
      } else {
        final product = productFromOp(op);
        final index = products.indexWhere(
          (item) =>
              item.id == product.id ||
              item.localId == op.id ||
              item.id == op.id,
        );
        if (index >= 0) {
          products[index] = product;
        } else {
          products.insert(0, product);
        }
      }
    }
  }

  void applyOpToCatalog({
    required LocalCreateOp op,
    required List<ListStoreModel> ownedStores,
    required List<ProductModel> products,
  }) {
    if (op.kind == LocalCreateKind.store) {
      final store = storeFromOp(op);
      final index = ownedStores.indexWhere(
        (item) => item.id == op.id || item.localId == op.id || item.id == store.id,
      );
      if (index >= 0) {
        ownedStores[index] = store;
      }
    } else if (op.kind == LocalCreateKind.productUpdate) {
      _overlayProductUpdate(op, products);
    } else {
      final product = productFromOp(op);
      final index = products.indexWhere(
        (item) =>
            item.id == op.id || item.localId == op.id || item.id == product.id,
      );
      if (index >= 0) {
        products[index] = product;
      }
    }
  }

  Future<void> process() async {
    if (_busy) {
      _wakeQueued = true;
      return;
    }
    _busy = true;
    try {
      do {
        _wakeQueued = false;
        await _drainOnce();
      } while (_wakeQueued);
    } finally {
      _busy = false;
      if (_wakeQueued) {
        unawaited(process());
      }
    }
  }

  Future<void> _drainOnce() async {
    if (NetworkStatus.isOffline.value) {
      await _markWaitingForNetwork();
      return;
    }

    for (final op in _opsForCurrentUser()) {
      if (op.status == LocalCreatePhase.waitingNetwork) {
        op.status = LocalCreatePhase.queued;
        op.errorMessage = null;
      }
    }

    while (true) {
      if (NetworkStatus.isOffline.value) {
        await _markWaitingForNetwork();
        return;
      }
      final next = _nextRunnable();
      if (next == null) return;
      final waitingForNetwork = await _processOne(next);
      if (waitingForNetwork) return;
    }
  }

  Future<void> _markWaitingForNetwork() async {
    var changed = false;
    for (final op in _opsForCurrentUser()) {
      if (op.status == LocalCreatePhase.queued ||
          op.status == LocalCreatePhase.uploading ||
          op.status == LocalCreatePhase.creating) {
        op.status = LocalCreatePhase.waitingNetwork;
        op.errorMessage = null;
        changed = true;
        applyOpToCatalog(
          op: op,
          ownedStores: _ownedStores,
          products: _products,
        );
      }
    }
    if (changed) {
      await persist();
      _onChanged();
    }
  }

  LocalCreateOp? _nextRunnable() {
    for (final op in _opsForCurrentUser()) {
      if (op.status == LocalCreatePhase.failed ||
          op.status == LocalCreatePhase.waitingNetwork) {
        continue;
      }
      if (op.kind == LocalCreateKind.product ||
          op.kind == LocalCreateKind.productUpdate) {
        if (op.dependsOnId != null) {
          final storeOp = opFor(op.dependsOnId!);
          if (storeOp != null && storeOp.isOpen) continue;
        }
        final storeId = (op.payload['storeId'] as String? ?? '').trim();
        final resolved = _resolvedStoreId(storeId, _ownedStores);
        if (int.tryParse(resolved) == null) continue;
        op.payload['storeId'] = resolved;
      }
      return op;
    }
    return null;
  }

  Future<bool> _processOne(LocalCreateOp op) async {
    try {
      if (op.kind == LocalCreateKind.store) {
        await _syncStore(op);
      } else if (op.kind == LocalCreateKind.productUpdate) {
        await _syncProductUpdate(op);
      } else {
        await _syncProduct(op);
      }
      return false;
    } on Object catch (error) {
      if (isNetworkFailure(error)) {
        NetworkStatus.reportError(error);
        op.status = LocalCreatePhase.waitingNetwork;
        op.errorMessage = null;
        applyOpToCatalog(
          op: op,
          ownedStores: _ownedStores,
          products: _products,
        );
        await persist();
        _onChanged();
        return true;
      }
      op.status = LocalCreatePhase.failed;
      op.errorMessage = error is ApiException
          ? error.message
          : 'Échec de synchronisation.';
      applyOpToCatalog(
        op: op,
        ownedStores: _ownedStores,
        products: _products,
      );
      await persist();
      _onChanged();
      return false;
    }
  }

  void _pushProgress(LocalCreateOp op, double progress, {bool force = false}) {
    op.progress = progress.clamp(0.0, 1.0);
    applyOpToCatalog(op: op, ownedStores: _ownedStores, products: _products);
    final now = DateTime.now();
    if (force ||
        _lastProgressPush == null ||
        now.difference(_lastProgressPush!) >= const Duration(milliseconds: 50)) {
      _lastProgressPush = now;
      _onChanged();
    }
  }

  Future<String> _uploadPath(
    String? path, {
    void Function(double progress)? onProgress,
  }) async {
    final trimmed = (path ?? '').trim();
    if (trimmed.isEmpty) {
      onProgress?.call(1);
      return '';
    }
    await _ensureSeller();
    return _uploads.uploadLocalImage(
      trimmed,
      purpose: 'catalog',
      onProgress: onProgress,
    );
  }

  Future<void> _ensureSeller() async {
    try {
      await _auth.becomeSeller();
    } on ApiException catch (error) {
      if (error.statusCode == 400 ||
          error.statusCode == 409 ||
          error.statusCode == 200) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _syncStore(LocalCreateOp op) async {
    op.status = LocalCreatePhase.uploading;
    _pushProgress(op, 0.08, force: true);
    await persist();

    await _ensureSeller();
    _pushProgress(op, 0.12, force: true);

    final hasBanner =
        (op.payload['bannerPath'] as String?)?.trim().isNotEmpty == true;
    final imageWeight = hasBanner ? 0.32 : 0.62;
    final imageUrl = await _uploadPath(
      op.payload['imagePath'] as String?,
      onProgress: (value) => _pushProgress(op, 0.12 + imageWeight * value),
    );
    final bannerUrl = await _uploadPath(
      op.payload['bannerPath'] as String?,
      onProgress: (value) =>
          _pushProgress(op, 0.12 + imageWeight + 0.26 * value),
    );
    op.payload['imagePath'] = imageUrl;
    if (bannerUrl.isNotEmpty) op.payload['bannerPath'] = bannerUrl;

    _pushProgress(op, 0.72, force: true);
    op.status = LocalCreatePhase.creating;
    _pushProgress(op, 0.82, force: true);
    await persist();

    Map<String, dynamic>? created;
    if (op.createRequestSent) {
      created = await _findStoreByName(op.payload['name'] as String? ?? '');
    }
    if (created == null) {
      op.createRequestSent = true;
      await persist();
      try {
        created = await _stores.createStore(
          name: op.payload['name'] as String? ?? '',
          description: op.payload['description'] as String?,
          address: op.payload['address'] as String?,
          image: imageUrl,
          bannerUrl: bannerUrl.isEmpty ? null : bannerUrl,
          whatsappUrl: op.payload['whatsappUrl'] as String?,
          instagramUrl: op.payload['instagramUrl'] as String?,
          facebookUrl: op.payload['facebookUrl'] as String?,
        );
      } on ApiException catch (error) {
        if (error.statusCode == 400) {
          created = await _findStoreByName(op.payload['name'] as String? ?? '');
        }
        if (created == null) rethrow;
      }
    }

    final store = _storeFromApi(created).copyWith(
      localId: op.id,
      syncStatus: EntitySyncStatus.online,
      syncProgress: 1,
    );
    op.serverId = store.id;
    op.status = LocalCreatePhase.completed;
    op.progress = 1;
    final index = _ownedStores.indexWhere(
      (item) => item.id == op.id || item.localId == op.id,
    );
    if (index >= 0) {
      _ownedStores[index] = store;
    } else {
      _ownedStores.insert(0, store);
    }
    if (!_publicStores.any((item) => item.id == store.id)) {
      _publicStores.insert(0, store);
    }
    for (var i = 0; i < _products.length; i++) {
      final product = _products[i];
      if (product.storeId == op.id) {
        _products[i] = product.copyWith(storeId: store.id);
      }
    }
    for (final child in _ops) {
      if (child.dependsOnId == op.id) {
        child.payload['storeId'] = store.id;
      }
    }
    _ops.removeWhere((item) => item.id == op.id);
    await persist();
    _onChanged();
  }

  Future<Map<String, dynamic>?> _findStoreByName(String name) async {
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final mine = await _stores.myStores();
    for (final item in mine) {
      if ((item['name'] as String? ?? '').trim().toLowerCase() == trimmed) {
        return item;
      }
    }
    return null;
  }

  Future<void> _syncProduct(LocalCreateOp op) async {
    final rawStoreId = (op.payload['storeId'] as String? ?? '').trim();
    final resolvedStoreId = _resolvedStoreId(rawStoreId, _ownedStores);
    final storeId = int.tryParse(resolvedStoreId);
    if (storeId == null) return;

    op.status = LocalCreatePhase.uploading;
    _pushProgress(op, 0.08, force: true);
    await persist();

    await _ensureSeller();
    _pushProgress(op, 0.12, force: true);

    final imageUrl = await _uploadPath(
      op.payload['imagePath'] as String?,
      onProgress: (value) => _pushProgress(op, 0.12 + 0.58 * value),
    );
    op.payload['imagePath'] = imageUrl;
    final variation = await _resolveVariations(
      op.payload['variation'] as Map<String, dynamic>?,
      onProgress: (value) => _pushProgress(op, 0.70 + 0.08 * value),
    );

    op.status = LocalCreatePhase.creating;
    _pushProgress(op, 0.82, force: true);
    await persist();

    final title = op.payload['title'] as String? ?? '';
    final storeName = op.payload['storeName'] as String? ?? '';
    ProductModel? created;
    if (op.createRequestSent) {
      created = await _findProductByTitle(
        storeId: storeId,
        storeName: storeName,
        title: title,
      );
    }
    if (created == null) {
      op.createRequestSent = true;
      await persist();
      await _productApi.addProduct(
        storeId: storeId,
        title: title,
        description: op.payload['description'] as String?,
        price: (op.payload['numericPrice'] as num?)?.toDouble() ?? 0,
        stock: 1,
        images: imageUrl.isEmpty ? null : [imageUrl],
        variation: variation,
      );
      created = await _findProductByTitle(
        storeId: storeId,
        storeName: storeName,
        title: title,
      );
    }
    if (created == null) {
      throw const ApiException(
        message: 'Produit créé mais introuvable dans le catalogue.',
      );
    }

    final synced = created.copyWith(
      localId: op.id,
      storeId: resolvedStoreId,
      syncStatus: EntitySyncStatus.online,
      syncProgress: 1,
    );
    op.serverId = synced.id;
    op.status = LocalCreatePhase.completed;
    op.progress = 1;
    final productIndex = _products.indexWhere(
      (item) => item.id == op.id || item.localId == op.id,
    );
    if (productIndex >= 0) {
      _products[productIndex] = synced;
    } else {
      _products.insert(0, synced);
    }
    if (synced.isActive &&
        !_homeProducts.any((item) => item.id == synced.id)) {
      _homeProducts.insert(0, synced);
    }
    _ops.removeWhere((item) => item.id == op.id);
    await persist();
    _onChanged();
  }

  String _resolvedStoreId(String storeId, List<ListStoreModel>? ownedStores) {
    if (int.tryParse(storeId) != null) return storeId;
    if (ownedStores == null) return storeId;
    for (final store in ownedStores) {
      if (store.id == storeId || store.localId == storeId) {
        return store.id;
      }
    }
    return storeId;
  }

  Map<String, dynamic> _productUpdatePayload(ProductModel product) {
    return {
      'productId': product.id,
      'storeId': product.storeId,
      'storeName': product.storeName,
      'title': product.name,
      'description': product.description,
      'price': product.price,
      'imagePath': product.imageurl,
      'category': product.category,
      'isActive': product.isActive,
      'localId': product.localId,
      'variation': _variationMap(product.variants),
      'variants': product.variants.map(_variantToJson).toList(),
    };
  }

  Map<String, dynamic> _variantToJson(ProductVariantModel variant) {
    return {
      'name': variant.name,
      'price': variant.price,
      'quantity': variant.quantity,
      'imageurl': variant.imageurl,
    };
  }

  Map<String, dynamic>? _variationMap(List<ProductVariantModel> variants) {
    if (variants.isEmpty) return null;
    return {
      for (final variant in variants)
        if (variant.name.trim().isNotEmpty)
          variant.name: {
            'price': variant.price,
            'quantity': variant.quantity,
            'image': variant.imageurl,
          },
    };
  }

  List<ProductVariantModel> _variantsFromPayload(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return ProductVariantModel(
        name: map['name'] as String? ?? '',
        price: map['price'] as String? ?? '',
        quantity: map['quantity'] as String? ?? '',
        imageurl: map['imageurl'] as String? ?? map['image'] as String? ?? '',
      );
    }).toList();
  }

  ProductModel _productFromUpdateOp(LocalCreateOp op, ProductModel current) {
    return current.copyWith(
      name: op.payload['title'] as String? ?? current.name,
      description: op.payload['description'] as String? ?? current.description,
      price: op.payload['price'] as String? ?? current.price,
      imageurl: op.payload['imagePath'] as String? ?? current.imageurl,
      category: op.payload['category'] as String? ?? current.category,
      isActive: op.payload['isActive'] as bool? ?? current.isActive,
      variants: _variantsFromPayload(op.payload['variants']),
      syncStatus: op.entityStatus,
      syncProgress: op.progress,
      syncError: op.errorMessage,
    );
  }

  void _overlayProductUpdate(LocalCreateOp op, List<ProductModel> products) {
    final productId = (op.payload['productId'] as String? ?? op.id).trim();
    final index = products.indexWhere(
      (item) =>
          item.id == productId ||
          item.id == op.id ||
          (item.localId.isNotEmpty && item.localId == op.id),
    );
    if (index < 0) return;
    products[index] = _productFromUpdateOp(op, products[index]);
  }

  void _replaceProduct(ProductModel product) {
    final index = _products.indexWhere(
      (item) =>
          item.id == product.id ||
          (product.localId.isNotEmpty && item.localId == product.localId),
    );
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.insert(0, product);
    }
    final homeIndex = _homeProducts.indexWhere((item) => item.id == product.id);
    if (product.isActive) {
      if (homeIndex >= 0) {
        _homeProducts[homeIndex] = product;
      } else {
        _homeProducts.insert(0, product);
      }
    } else if (homeIndex >= 0) {
      _homeProducts.removeAt(homeIndex);
    }
  }

  Future<void> _syncProductUpdate(LocalCreateOp op) async {
    final rawStoreId = (op.payload['storeId'] as String? ?? '').trim();
    final resolvedStoreId = _resolvedStoreId(rawStoreId, _ownedStores);
    final storeId = int.tryParse(resolvedStoreId);
    final productId = int.tryParse(
      (op.payload['productId'] as String? ?? op.id).trim(),
    );
    if (storeId == null || productId == null) return;

    op.status = LocalCreatePhase.uploading;
    _pushProgress(op, 0.08, force: true);
    await persist();

    await _ensureSeller();
    _pushProgress(op, 0.12, force: true);

    final imageUrl = await _uploadPath(
      op.payload['imagePath'] as String?,
      onProgress: (value) => _pushProgress(op, 0.12 + 0.50 * value),
    );
    op.payload['imagePath'] = imageUrl;
    Map<String, dynamic>? variationInput;
    final rawVariation = op.payload['variation'];
    if (rawVariation is Map && rawVariation.isNotEmpty) {
      variationInput = Map<String, dynamic>.from(rawVariation);
    } else {
      variationInput = _variationMap(
        _variantsFromPayload(op.payload['variants']),
      );
    }
    final variation = await _resolveVariations(
      variationInput,
      onProgress: (value) => _pushProgress(op, 0.62 + 0.16 * value),
    );
    if (variation != null) {
      op.payload['variation'] = variation;
      final variants = _variantsFromPayload(op.payload['variants']);
      op.payload['variants'] = variants.map((variant) {
        final uploaded = variation[variant.name];
        final image = uploaded is Map
            ? (uploaded['image'] as String? ?? variant.imageurl)
            : variant.imageurl;
        return _variantToJson(
          ProductVariantModel(
            name: variant.name,
            price: variant.price,
            quantity: variant.quantity,
            imageurl: image,
          ),
        );
      }).toList();
    }

    op.status = LocalCreatePhase.creating;
    _pushProgress(op, 0.84, force: true);
    await persist();

    final priceDigits = (op.payload['price'] as String? ?? '').replaceAll(
      RegExp(r'[^\d.]'),
      '',
    );
    await _productApi.updateProduct(
      storeId: storeId,
      productId: productId,
      title: op.payload['title'] as String? ?? '',
      description: op.payload['description'] as String?,
      price: double.tryParse(priceDigits),
      isActive: op.payload['isActive'] as bool?,
      images: imageUrl.isEmpty ? null : [imageUrl],
      variation: variation,
    );

    final index = _products.indexWhere(
      (item) => item.id == op.id || item.id == '$productId',
    );
    if (index >= 0) {
      final synced = _productFromUpdateOp(op, _products[index]).copyWith(
        syncStatus: EntitySyncStatus.online,
        syncProgress: 1,
      );
      _replaceProduct(synced);
    }
    op.status = LocalCreatePhase.completed;
    op.progress = 1;
    _ops.removeWhere((item) => item.id == op.id);
    await persist();
    _onChanged();
  }

  Future<Map<String, dynamic>?> _resolveVariations(
    Map<String, dynamic>? variation, {
    void Function(double progress)? onProgress,
  }) async {
    if (variation == null || variation.isEmpty) {
      onProgress?.call(1);
      return null;
    }
    final resolved = <String, dynamic>{};
    final entries = variation.entries.toList();
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final value = entry.value;
      if (value is! Map) {
        resolved[entry.key] = value;
        continue;
      }
      final item = Map<String, dynamic>.from(value);
      final image = (item['image'] as String?)?.trim() ?? '';
      if (image.isNotEmpty) {
        item['image'] = await _uploadPath(
          image,
          onProgress: (value) {
            final base = index / entries.length;
            final span = 1 / entries.length;
            onProgress?.call(base + span * value);
          },
        );
      }
      resolved[entry.key] = item;
      onProgress?.call((index + 1) / entries.length);
    }
    return resolved;
  }

  Future<ProductModel?> _findProductByTitle({
    required int storeId,
    required String storeName,
    required String title,
  }) async {
    final response = await _productApi.productsForStore(
      storeId,
      includeInactive: true,
    );
    final parsed = _productApi.parseProductsForStore(
      response,
      storeName: storeName,
    );
    final needle = title.trim().toLowerCase();
    for (final product in parsed) {
      if (product.name.trim().toLowerCase() == needle) return product;
    }
    return parsed.isEmpty ? null : parsed.first;
  }
}
