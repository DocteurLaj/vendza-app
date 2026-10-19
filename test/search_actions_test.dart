import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/utils/search/search_actions.dart';
import 'package:vendza/core/utils/search/search_results_page.dart';

void main() {
  testWidgets('search ignores whitespace-only input', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    handleSearch('   ', context);
    await tester.pumpAndSettle();

    expect(find.byType(SearchResultsPage), findsNothing);
  });

  testWidgets('search trims the query before navigation', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );

    handleSearch('  chaussures  ', context);
    await tester.pumpAndSettle();

    final page = tester.widget<SearchResultsPage>(
      find.byType(SearchResultsPage),
    );
    expect(page.query, 'chaussures');
  });
}
