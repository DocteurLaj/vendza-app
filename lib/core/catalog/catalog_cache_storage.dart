import 'catalog_cache_storage_io.dart'
    if (dart.library.html) 'catalog_cache_storage_web.dart'
    if (dart.library.js_interop) 'catalog_cache_storage_web.dart' as impl;

Future<String?> readCatalogCacheJson() => impl.readCatalogCacheJson();

Future<void> writeCatalogCacheJson(String json) =>
    impl.writeCatalogCacheJson(json);
