import 'package:flutter/material.dart';
import 'package:vendza/core/utils/search/catalog_search.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as detail;
import 'package:vendza/features/order/data/models/order_model.dart';
import 'package:vendza/features/order/data/services/order_store.dart';
import 'package:vendza/features/order/presentation/pages/order_pages.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
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
  void initState() {
    super.initState();
    refreshBuyerOrders().catchError((_) => <OrderModel>[]);
  }

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
              valueListenable: favoriteStoreChanges,
              builder: (context, _, _) {
                final filteredFavorites = favoriteStores
                    .where((store) => matchesStoreListItem(_searchQuery, store))
                    .toList();
                final filteredOwned = stores
                    .where((store) => matchesStoreListItem(_searchQuery, store))
                    .toList();

                return SingleChildScrollView(
                  child: ResponsiveContent(
                    maxWidth: 920,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<List<OrderModel>>(
                          valueListenable: buyerOrderStore,
                          builder: (context, orders, _) {
                            if (orders.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                              child: Material(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(18),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.receipt_long_outlined),
                                  ),
                                  title: const Text(
                                    'Mes commandes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${orders.length} commande${orders.length > 1 ? 's' : ''} · ${orders.where((order) => !order.isHistory).length} en cours',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const BuyerOrdersPage(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        StoreListSection(
                          title: "Mes favoris",
                          stores: filteredFavorites,
                          emptyText: "Les boutiques aimees apparaitront ici.",
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
                                    deliveryEnabled: store.deliveryEnabled,
                                    adminHidden: store.adminHidden,
                                    moderationReason: store.moderationReason,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        StoreListSection(
                          title: "Mes stores",
                          stores: filteredOwned,
                          emptyText: "Vous n'avez pas encore cree de boutique.",
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
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                            width: double.infinity,
                            child: AppBouton(
                              text: "Créer un store",
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
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
