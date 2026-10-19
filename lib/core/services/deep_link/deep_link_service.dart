import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vendza/core/services/deep_link/deep_link_content_resolver.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/features/auth/presantation/pages/reset_password_page.dart';
import 'package:vendza/features/product/presentation/pages/product_detail_page.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/subscription/presentation/pages/payment_return_handler.dart';
import 'package:vendza/navigation/app_navigator.dart';

sealed class DeepLinkTarget {
  const DeepLinkTarget();

  const factory DeepLinkTarget.product(String id) = ProductDeepLink;
  const factory DeepLinkTarget.store(String id) = StoreDeepLink;
  const factory DeepLinkTarget.resetPassword(String token) =
      ResetPasswordDeepLink;
  const factory DeepLinkTarget.paymentReturn(int paymentId) =
      PaymentReturnDeepLink;
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

final class PaymentReturnDeepLink extends DeepLinkTarget {
  const PaymentReturnDeepLink(this.paymentId);

  final int paymentId;
}

typedef ProductPageBuilder = Widget Function(ProductModel product);
typedef StorePageBuilder = Widget Function(StoreModel store);

class DeepLinkService {
  DeepLinkService._({
    GlobalKey<NavigatorState>? navigatorKey,
    DeepLinkContentResolver? resolver,
    ProductPageBuilder? productPageBuilder,
    StorePageBuilder? storePageBuilder,
    AppLinks? appLinks,
  }) : _navigatorKey = navigatorKey ?? rootNavigatorKey,
       _resolverOverride = resolver,
       _productPageBuilder =
           productPageBuilder ??
           ((product) => ProductDetailPage(product: product)),
       _storePageBuilder =
           storePageBuilder ?? ((store) => StoreDetailPage(store: store)),
       _appLinksOverride = appLinks;

  static final DeepLinkService instance = DeepLinkService._();

  @visibleForTesting
  factory DeepLinkService.forTesting({
    required GlobalKey<NavigatorState> navigatorKey,
    required DeepLinkContentResolver resolver,
    required ProductPageBuilder productPageBuilder,
    required StorePageBuilder storePageBuilder,
  }) => DeepLinkService._(
    navigatorKey: navigatorKey,
    resolver: resolver,
    productPageBuilder: productPageBuilder,
    storePageBuilder: storePageBuilder,
  );

  final GlobalKey<NavigatorState> _navigatorKey;
  final DeepLinkContentResolver? _resolverOverride;
  DeepLinkContentResolver? _defaultResolver;
  DeepLinkContentResolver get _resolver =>
      _resolverOverride ?? (_defaultResolver ??= DeepLinkContentResolver());
  final ProductPageBuilder _productPageBuilder;
  final StorePageBuilder _storePageBuilder;
  final AppLinks? _appLinksOverride;
  AppLinks? _appLinksInstance;
  AppLinks get _appLinks =>
      _appLinksOverride ?? (_appLinksInstance ??= AppLinks());

  /// Links currently being resolved, keyed by target, so that the same link
  /// delivered twice (initial link + stream, double tap) opens one page.
  final Set<String> _inFlight = <String>{};
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

  @visibleForTesting
  void handleUriForTesting(Uri uri) => _handleUri(uri);

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
      if (host == 'payment-return') {
        final rawId = uri.queryParameters['payment_id'];
        final paymentId = rawId != null ? int.tryParse(rawId) : null;
        if (paymentId != null) return DeepLinkTarget.paymentReturn(paymentId);
      }
    }

    final webHost = uri.host.toLowerCase();
    const vendzaWebHosts = {
      // Only domains Vendza controls. vendza.app belongs to a third party and
      // must never be trusted (it could hand the app a reset-password token).
      'app.vendza.online',
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
      // https://app.vendza.online/subscription/payment-return?payment_id=N
      if (segments.length >= 2 &&
          segments[0] == 'subscription' &&
          segments[1] == 'payment-return') {
        final rawId = uri.queryParameters['payment_id'];
        final paymentId = rawId != null ? int.tryParse(rawId) : null;
        if (paymentId != null) return DeepLinkTarget.paymentReturn(paymentId);
      }
    }

    return null;
  }

  void _navigate(Uri uri) {
    final target = parseDeepLink(uri);
    if (target == null) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _pendingUri = uri;
      return;
    }

    switch (target) {
      case ProductDeepLink(:final id):
        _openResolved(
          key: 'p/$id',
          uri: uri,
          load: () async =>
              _productPageBuilder((await _resolver.resolveProduct(id)).product),
        );
      case StoreDeepLink(:final id):
        _openResolved(
          key: 'store/$id',
          uri: uri,
          load: () async => _storePageBuilder(await _resolver.resolveStore(id)),
        );
      case ResetPasswordDeepLink(:final token):
        _resetRouteOpen = true;
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(token: token),
          ),
          (route) => false,
        );
      case PaymentReturnDeepLink(:final paymentId):
        // Show the payment verification popup on top of the current screen.
        final context = navigator.context;
        handlePaymentReturn(context, paymentId);
    }
  }

  Future<void> _openResolved({
    required String key,
    required Uri uri,
    required Future<Widget> Function() load,
  }) async {
    if (!_inFlight.add(key)) return;
    try {
      final page = await load();
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      navigator.push(MaterialPageRoute(builder: (context) => page));
    } on DeepLinkNotFoundException {
      _showNotFound();
    } catch (error) {
      // Network/server failure: the content may exist, so offer a retry
      // instead of claiming it is missing.
      debugPrint('deep_link_resolve_failed target=$key error=$error');
      _showRetry(uri);
    } finally {
      _inFlight.remove(key);
    }
  }

  void _showRetry(Uri uri) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: const Text('Impossible d’ouvrir ce contenu'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: () => _navigate(uri),
        ),
      ),
    );
  }

  void _showNotFound() {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Contenu introuvable')));
  }
}
