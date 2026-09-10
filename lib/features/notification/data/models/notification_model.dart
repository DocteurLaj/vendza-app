class NotificationModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isRead;
  final int? storeId;
  final int? orderId;

  NotificationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isRead,
    this.storeId,
    this.orderId,
  });
}
