import 'package:flutter/foundation.dart';
import 'package:vendza/core/services/push_notification_service.dart';

final notificationsEnabledStore = ValueNotifier<bool>(true);

void setNotificationsEnabled(bool enabled) {
  notificationsEnabledStore.value = enabled;
}

Future<void> setNotificationsEnabledAndSync(bool enabled) async {
  notificationsEnabledStore.value = enabled;
  if (enabled) {
    await pushNotificationService.syncCurrentToken();
  } else {
    await pushNotificationService.disableCurrentUserPush();
  }
}
