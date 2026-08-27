import 'package:flutter/material.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/core/utils/search/catalog_search.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/store/presentation/widgets/store_catalog_card.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';

class SearchResultsPage extends StatelessWidget {
  const SearchResultsPage(this.query, {super.key});

  final String query;

  @override
  Widget build(BuildContext context) {
    final results = searchCatalog(query);
    final hasResults = results.stores.isNotEmpty || results.products.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: ResponsiveContent(maxWidth: 720, child: SearchBarWidget()),
      ),
      body: ResponsiveContent(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Résultats pour "$query"',
                style: AppTextStyles.pageTitle(context),
              ),
            ),
            Expanded(
              child: hasResults
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (results.stores.isNotEmpty) ...[
                            Text(
                              'Boutiques',
                              style: AppTextStyles.sectionLabel(context),
                            ),
                            const SizedBox(height: 8),
                            for (final store in results.stores) ...[
                              StoreCatalogCard(
                                store: store,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StoreDetailPage(store: store),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 8),
                          ],
                          if (results.products.isNotEmpty) ...[
                            Text(
                              'Produits',
                              style: AppTextStyles.sectionLabel(context),
                            ),
                            const SizedBox(height: 8),
                            ProductSectionWidget(products: results.products),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    )
                  : EmptyStateWidget(
                      icon: Icons.search_off_outlined,
                      title: 'Aucun résultat',
                      message:
                          'Essayez un autre mot-clé (boutique, produit, catégorie).',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
