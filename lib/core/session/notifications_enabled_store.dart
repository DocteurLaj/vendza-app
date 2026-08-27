import 'package:flutter/foundation.dart';

final notificationsEnabledStore = ValueNotifier<bool>(true);

void setNotificationsEnabled(bool enabled) {
  notificationsEnabledStore.value = enabled;
}
