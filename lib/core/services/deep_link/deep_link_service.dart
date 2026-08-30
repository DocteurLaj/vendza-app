import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vendza/core/services/deep_link/catalog_lookup.dart';
import 'package:vendza/features/auth/presantation/pages/reset_password_page.dart';
import 'package:vendza/features/product/presentation/pages/product_detail_page.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/navigation/app_navigator.dart';

sealed class DeepLinkTarget {
  const DeepLinkTarget();

  const factory DeepLinkTarget.product(String id) = ProductDeepLink;
  const factory DeepLinkTarget.store(String id) = StoreDeepLink;
  const factory DeepLinkTarget.resetPassword(String token) =
      ResetPasswordDeepLink;
}

final class ProductDeepLink extends DeepLinkTarget {
  const ProductDeepLink(this.id);

  final String id;
}

final class StoreDeepLink extends DeepLinkTarget {
  const StoreDeepLink(this.id);

  final String id;
}

final class ResetPasswordDeepLink extends DeepLinkTarget {
  const ResetPasswordDeepLink(this.token);

  final String token;
}

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  Uri? _pendingUri;
  bool _navigationReady = false;
  bool _authNavigationReady = false;
  bool _resetRouteOpen = false;

  bool get isResetRouteOpen => _resetRouteOpen;

  Future<void> init() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    } else if (kIsWeb) {
      _handleUri(Uri.base);
    }

    _subscription = _appLinks.uriLinkStream.listen(_handleUri);
  }

  void markNavigationReady() {
    _navigationReady = true;
    _authNavigationReady = true;
    flushPendingLink();
  }

  void markAuthNavigationReady() {
    _authNavigationReady = true;
    flushPendingLink();
  }

  void flushPendingLink() {
    if (_pendingUri == null) return;

    final target = parseDeepLink(_pendingUri!);
    final canNavigate = target is ResetPasswordDeepLink
        ? _authNavigationReady
        : _navigationReady;
    if (!canNavigate) return;

    final uri = _pendingUri!;
    _pendingUri = null;
    _navigate(uri);
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _handleUri(Uri uri) {
    final target = parseDeepLink(uri);
    if (target == null) return;
    final canNavigate = target is ResetPasswordDeepLink
        ? _authNavigationReady
        : _navigationReady;
    if (!canNavigate) {
      _pendingUri = uri;
      return;
    }
    _navigate(uri);
  }

  DeepLinkTarget? parseDeepLink(Uri uri) {
    if (uri.scheme == 'vendza') {
      final host = uri.host;
      final id = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : uri.path.replaceFirst('/', '');

      if (host == 'p' && id.isNotEmpty) {
        return DeepLinkTarget.product(id);
      }
      if (host == 'store' && id.isNotEmpty) {
        return DeepLinkTarget.store(id);
      }
      if (host == 'reset-password') {
        return DeepLinkTarget.resetPassword(uri.queryParameters['token'] ?? '');
      }
    }

    final webHost = uri.host.toLowerCase();
    const vendzaWebHosts = {
      'vendza.app',
      'www.vendza.app',
      'vendza.online',
      'www.vendza.online',
    };
    final isLocalDebugHost =
        kDebugMode && (webHost == 'localhost' || webHost == '127.0.0.1');
    final isTrustedWebHost =
        vendzaWebHosts.contains(webHost) || isLocalDebugHost;
    final isAllowedWebScheme =
        uri.scheme == 'https' || (isLocalDebugHost && uri.scheme == 'http');

    if (isAllowedWebScheme && isTrustedWebHost) {
      final segments = uri.pathSegments;
      if (vendzaWebHosts.contains(webHost)) {
        if (segments.length >= 2 && segments[0] == 'p') {
          return DeepLinkTarget.product(segments[1]);
        }
        if (segments.length >= 2 && segments[0] == 'store') {
          return DeepLinkTarget.store(segments[1]);
        }
      }
      if (segments.isNotEmpty && segments.first == 'reset-password') {
        return DeepLinkTarget.resetPassword(uri.queryParameters['token'] ?? '');
      }
    }

    return null;
  }

  void _navigate(Uri uri) {
    final target = parseDeepLink(uri);
    if (target == null) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      _pendingUri = uri;
      return;
    }

    switch (target) {
      case ProductDeepLink(:final id):
        final product = findProductById(id);
        if (product == null) {
          _showNotFound();
          return;
        }
        navigator.push(
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      case StoreDeepLink(:final id):
        final store = findStoreById(id);
        if (store == null) {
          _showNotFound();
          return;
        }
        navigator.push(
          MaterialPageRoute(
            builder: (context) => StoreDetailPage(store: store),
          ),
        );
      case ResetPasswordDeepLink(:final token):
        _resetRouteOpen = true;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(token: token),
          ),
          (route) => false,
        );
    }
  }

  void _showNotFound() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contenu introuvable')));
  }
}
