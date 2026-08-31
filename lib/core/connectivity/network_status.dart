import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vendza/core/services/api_exception.dart';

bool isNetworkFailure(Object error) {
  if (error is TimeoutException || error is http.ClientException) {
    return true;
  }
  if (error is ApiException) {
    if (error.statusCode == 408) return true;
    if (error.statusCode != null) return false;
    final message = error.message.toLowerCase();
    if (message.contains('introuvable') ||
        message.contains('invalide') ||
        message.contains('volumineuse') ||
        message.contains('ajoutez une image')) {
      return false;
    }
    return true;
  }
  final label = error.toString().toLowerCase();
  return label.contains('socketexception') ||
      label.contains('failed host lookup') ||
      label.contains('network is unreachable') ||
      label.contains('connection refused') ||
      label.contains('connection reset');
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
    if (_subscription != null) {
      await recheck();
      return;
    }
    try {
      final connectivity = Connectivity();
      _applyResults(await connectivity.checkConnectivity());
      _subscription = connectivity.onConnectivityChanged.listen(_applyResults);
    } on Object {
      // Plugin may be unavailable in tests or some hosts.
    }
  }

  static bool _isOfflineResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.every((result) => result == ConnectivityResult.none);
  }

  static void _applyResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return;
    if (_isOfflineResult(results)) {
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
      unawaited(recheck());
    }
  }

  static Future<void> recheck() async {
    try {
      _applyResults(await Connectivity().checkConnectivity());
    } on Object {
      // Keep the last known status if the plugin cannot answer.
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
