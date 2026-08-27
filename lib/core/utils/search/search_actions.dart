import 'package:flutter/material.dart';
import 'package:vendza/core/utils/search/search_results_page.dart';

void handleSearch(String query, BuildContext context) {
  if (query.trim().isEmpty) {
    debugPrint('Veuillez entrer un terme de recherche');
    return;
  }

  debugPrint('Recherche: $query');

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SearchResultsPage(query)),
  );
}
