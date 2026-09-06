import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';

Widget? buildGoogleSignInWebButton({
  required bool enabled,
  required AuthSessionService? sessionService,
  required ValueChanged<bool> onLoadingChanged,
  required FutureOr<void> Function() onAuthenticated,
  required ValueChanged<String> onError,
}) {
  return null;
}
