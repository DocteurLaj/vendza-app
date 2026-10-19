import 'package:flutter/material.dart';
import 'package:vendza/core/utils/search/search_results_page.dart';

void handleSearch(String query, BuildContext context) {
  final normalizedQuery = query.trim();
  if (normalizedQuery.isEmpty) return;

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SearchResultsPage(normalizedQuery)),
  );
}
