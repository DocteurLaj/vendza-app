import 'dart:async';

import 'package:vendza/core/services/api_client.dart';
import 'package:vendza/core/services/api_endpoints.dart';
import 'package:vendza/core/services/api_token_store.dart';

/// Search intent is recorded once on submit, not for every local filter edit.
class SearchEventApiService {
  SearchEventApiService({ApiClient? client, ApiTokenStore? tokenStore})
    : _client = client ?? apiClient,
      _tokenStore = tokenStore ?? apiTokenStore;

  final ApiClient _client;
  final ApiTokenStore _tokenStore;

  Future<void> track(String query, {int resultsCount = 0}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2 || !_tokenStore.hasAccessToken) return;
    await _client.post(
      ApiEndpoints.eventsSearch,
      authenticated: true,
      body: {'query': trimmed, 'results_count': resultsCount},
    );
  }

  void trackSafely(String query) {
    unawaited(
      Future(() async {
        try {
          await track(query);
        } catch (_) {
          // Search remains usable when analytics cannot be delivered.
        }
      }),
    );
  }
}

final searchEventApiService = SearchEventApiService();
