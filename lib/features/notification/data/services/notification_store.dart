export 'package:vendza/core/catalog/catalog_repository.dart'
    show notificationStore;

import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_api_service.dart';

int unreadNotificationCount(List<NotificationModel> notifications) {
  return notifications.where((notification) => !notification.isRead).length;
}

Future<void> markNotificationAsRead(String id) async {
  final alreadyRead = notificationStore.value.any(
    (notification) => notification.id == id && notification.isRead,
  );
  if (alreadyRead) return;

  notificationStore.value = notificationStore.value.map((notification) {
    if (notification.id != id || notification.isRead) return notification;
    return notification.copyWith(isRead: true);
  }).toList();

  final notificationId = int.tryParse(id);
  if (notificationId == null) return;

  try {
    await NotificationApiService().markAsSeen(notificationId);
  } on Object {
    // Keep optimistic local read state; inbox refresh can reconcile later.
  }
}

Future<void> deleteNotificationLocallyAndRemote(String id) async {
  final before = List<NotificationModel>.from(notificationStore.value);
  notificationStore.value = before
      .where((notification) => notification.id != id)
      .toList(growable: false);

  final notificationId = int.tryParse(id);
  if (notificationId == null) return;

  try {
    await NotificationApiService().deleteNotification(notificationId);
  } on Object {
    notificationStore.value = before;
  }
}

Future<void> deleteNotificationThreadLocallyAndRemote(String threadId) async {
  final before = List<NotificationModel>.from(notificationStore.value);
  notificationStore.value = before
      .where((notification) => notification.threadKey != threadId)
      .toList(growable: false);

  try {
    await NotificationApiService().deleteThread(threadId);
  } on Object {
    notificationStore.value = before;
  }
}
