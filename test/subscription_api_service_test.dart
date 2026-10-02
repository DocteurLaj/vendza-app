import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';
import 'package:vendza/features/subscription/data/services/subscription_api_service.dart';

void main() {
  test('parses subscription plans from API response', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/subscription/plans');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 1,
                'code': 'free',
                'name': 'Gratuit',
                'price_monthly': '0',
                'currency': 'FCFA',
                'duration_days': 30,
                'description': 'Pour commencer',
                'features': {
                  'max_stores': 1,
                  'max_active_products': 10,
                  'max_images_per_product': 1,
                  'max_store_collections': 0,
                  'max_social_links': 1,
                  'has_banner': false,
                  'has_variants': false,
                  'visibility_boost': 'none',
                },
                'is_active': true,
              },
              {
                'id': 2,
                'code': 'active',
                'name': 'Actif',
                'price_monthly': '5000',
                'currency': 'FCFA',
                'duration_days': 30,
                'description': 'Pour vendre régulièrement',
                'features': {
                  'max_stores': 1,
                  'max_active_products': 100,
                  'max_images_per_product': 3,
                  'max_store_collections': 10,
                  'max_featured_products': 5,
                  'max_social_links': 3,
                  'has_banner': true,
                  'has_variants': true,
                  'has_basic_stats': true,
                  'visibility_boost': 'light',
                },
                'is_active': true,
              },
            ],
          }),
          200,
        );
      }),
    );

    final plans = await SubscriptionApiService(client: client).listPlans();

    expect(plans, hasLength(2));
    expect(plans.first.title, 'Gratuit');
    expect(plans.first.isFree, isTrue);
    expect(plans.last.formattedPrice, '5000 FCFA');
    expect(plans.last.features, contains('100 produits actifs'));
    expect(plans.last.features, contains('Bannière de boutique'));
    expect(plans.last.features, contains('Variantes produit'));
    expect(plans.last.features, contains('Boost visibilité léger'));
  });

  test('parses current subscription context', () async {
    final context = SubscriptionContextModel.fromJson({
      'plan': {
        'id': 3,
        'code': 'pro',
        'name': 'Boutique Pro',
        'price_monthly': '15000',
        'currency': 'FCFA',
        'duration_days': 30,
        'features': {'max_active_products': 300},
      },
      'subscription': {'status': 'active'},
      'features': {'max_active_products': 300},
      'usage': {'active_products': 12, 'stores': 1},
    });

    expect(context.plan.title, 'Boutique Pro');
    expect(context.status, 'active');
    expect(context.features.intValue('max_active_products'), 300);
    expect(context.usage.value('active_products'), 12);
  });

  test('detects structured plan limit API errors', () {
    const error = ApiException(
      message: 'Votre offre actuelle permet 10 produits actifs.',
      statusCode: 402,
      body: {
        'code': 'plan_limit_reached',
        'detail': {
          'error': 'plan_limit_reached',
          'feature': 'max_active_products',
          'message': 'Votre offre actuelle permet 10 produits actifs.',
          'current_plan': 'Gratuit',
          'required_plan': 'Débutant',
          'upgrade_action': 'open_subscription_page',
        },
      },
    );

    expect(error.isPlanLimitReached, isTrue);
    expect(error.planLimitDetail?['required_plan'], 'Débutant');
  });

  test('creates checkout and parses payment status', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        if (request.url.path == '/subscription/checkout') {
          expect(jsonDecode(request.body), {'plan_code': 'active'});
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'payment_id': 7,
                'provider': 'saspay',
                'checkout_url': 'https://pay.saspay.me/checkout/test',
                'provider_reference': 'checkout-1',
                'status': 'pending',
                'amount': '5000.00',
                'currency': 'CDF',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/subscription/payments/7/status') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'payment_id': 7,
                'provider': 'saspay',
                'provider_reference': 'checkout-1',
                'status': 'paid',
                'transaction_status': 'SUCCESS',
                'subscription_active': true,
                'plan': {
                  'id': 2,
                  'code': 'active',
                  'name': 'Actif',
                  'price_monthly': '5000',
                  'currency': 'FCFA',
                  'duration_days': 30,
                  'features': {'max_active_products': 100},
                },
              },
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      }),
    );
    final service = SubscriptionApiService(client: client);

    final checkout = await service.createCheckout('active');
    final status = await service.paymentStatus(checkout.paymentId);

    expect(checkout.paymentId, 7);
    expect(checkout.currency, 'CDF');
    expect(checkout.checkoutUrl, startsWith('https://pay.saspay.me'));
    expect(status.subscriptionActive, isTrue);
    expect(status.plan?.code, 'active');
  });
}
