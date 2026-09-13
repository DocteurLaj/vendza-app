class NotificationModel {
  final String id;
  final String name;
  final String title;
  final String description;
  final String imageUrl;
  final bool isRead;
  final int? storeId;
  final int? orderId;
  final int? productId;
  final String? threadId;
  final String? threadType;
  final String? storeName;
  final String? storeImage;
  final String? productName;
  final String? productImage;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.name,
    String? title,
    required this.description,
    required this.imageUrl,
    required this.isRead,
    this.storeId,
    this.orderId,
    this.productId,
    this.threadId,
    this.threadType,
    this.storeName,
    this.storeImage,
    this.productName,
    this.productImage,
    this.createdAt,
  }) : title = title ?? name;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      name: name,
      title: title,
      description: description,
      imageUrl: imageUrl,
      isRead: isRead ?? this.isRead,
      storeId: storeId,
      orderId: orderId,
      productId: productId,
      threadId: threadId,
      threadType: threadType,
      storeName: storeName,
      storeImage: storeImage,
      productName: productName,
      productImage: productImage,
      createdAt: createdAt,
    );
  }

  String get threadKey {
    return threadId ??
        (orderId != null
            ? 'order:$orderId'
            : storeId != null
            ? 'store:$storeId'
            : name);
  }
}

class NotificationThreadModel {
  NotificationThreadModel({required this.id, required this.messages});

  final String id;
  final List<NotificationModel> messages;

  NotificationModel get latest => messages.reduce(
    (a, b) =>
        (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).isAfter(
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        )
        ? a
        : b,
  );

  int get unreadCount => messages.where((message) => !message.isRead).length;
  int get messageCount => messages.length;
  String get title => latest.storeName ?? latest.title;
  String get imageUrl => latest.imageUrl;
}

List<NotificationThreadModel> groupNotificationThreads(
  List<NotificationModel> notifications,
) {
  final grouped = <String, List<NotificationModel>>{};
  for (final notification in notifications) {
    final id = notification.threadKey;
    grouped.putIfAbsent(id, () => []).add(notification);
  }
  final threads = grouped.entries
      .map(
        (entry) =>
            NotificationThreadModel(id: entry.key, messages: entry.value),
      )
      .toList();
  threads.sort((a, b) {
    final ad = a.latest.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.latest.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });
  return threads;
}
