import 'package:flutter/material.dart';
import 'package:vendza/core/utils/search/catalog_search.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as detail;
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';
import 'package:vendza/features/store/presentation/pages/add_store_page.dart';
import 'package:vendza/features/store/presentation/pages/my_store_product_page.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/store/presentation/widgets/store_list_section.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';

class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Mes Stores")),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ResponsiveContent(
            maxWidth: 720,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: "Rechercher un store...",
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: catalogRevision,
              builder: (context, _, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: favoriteStoreChanges,
                  builder: (context, _, _) {
                    final filteredFavorites = favoriteStores
                        .where(
                          (store) => matchesStoreListItem(_searchQuery, store),
                        )
                        .toList();
                    final filteredOwned = ownedStores
                        .where(
                          (store) => matchesStoreListItem(_searchQuery, store),
                        )
                        .toList();

                    return RefreshIndicator(
                      onRefresh: () =>
                          catalogRepository.softRefreshCatalog(force: true),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ResponsiveContent(
                          maxWidth: 920,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  16,
                                ),
                                child: ListTile(
                                  tileColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: const Icon(
                                    Icons.receipt_long_outlined,
                                  ),
                                  title: const Text('Mes commandes'),
                                  subtitle: const Text(
                                    'Voir les commandes passees',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const BuyerOrdersPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              StoreListSection(
                                title: "Mes favoris",
                                stores: filteredFavorites,
                                emptyText:
                                    "Les boutiques aimees apparaitront ici.",
                                onStoreTap: (store) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StoreDetailPage(
                                        store: detail.StoreModel(
                                          id: store.id,
                                          name: store.name,
                                          image: store.imageUrl,
                                          description: store.description,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              StoreListSection(
                                title: "Mes stores",
                                stores: filteredOwned,
                                emptyText:
                                    "Vous n'avez pas encore cree de boutique.",
                                onStoreTap: (store) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MyStoreProductPage(store: store),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: AppBouton(
                                  text: "Creer un store",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AddStore(),
                                      ),
                                    );
                                  },
                                  enabled: true,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
