import 'local_create_queue_storage_io.dart'
    if (dart.library.html) 'local_create_queue_storage_web.dart'
    if (dart.library.js_interop) 'local_create_queue_storage_web.dart' as impl;

Future<String?> readLocalCreateQueueJson() => impl.readLocalCreateQueueJson();

Future<void> writeLocalCreateQueueJson(String json) =>
    impl.writeLocalCreateQueueJson(json);
