import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:vendza/core/services/api_exception.dart';

bool isNetworkFailure(Object error) {
  if (error is ApiException) {
    return error.statusCode == null;
  }
  return true;
}

bool isConfirmedAuthFailure(Object error) {
  return error is ApiException &&
      (error.statusCode == 401 || error.statusCode == 403);
}

class NetworkStatus {
  NetworkStatus._();

  static final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static Future<void> start() async {
    if (_subscription != null) return;
    try {
      final connectivity = Connectivity();
      _applyResults(await connectivity.checkConnectivity());
      _subscription = connectivity.onConnectivityChanged.listen(_applyResults);
    } on Object {
      // Plugin may be unavailable in tests or some hosts.
    }
  }

  static void _applyResults(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    if (offline) {
      reportOffline();
    } else {
      reportOnline();
    }
  }

  static void reportOnline() {
    if (isOffline.value) isOffline.value = false;
  }

  static void reportOffline() {
    if (!isOffline.value) isOffline.value = true;
  }

  static void reportError(Object error) {
    if (isNetworkFailure(error) && !isConfirmedAuthFailure(error)) {
      reportOffline();
    }
  }

  /// Returns false and shows a message when the device is offline.
  static bool ensureOnline(BuildContext context) {
    if (!isOffline.value) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vous êtes hors connexion. Cette action nécessite Internet.',
        ),
      ),
    );
    return false;
  }
}
