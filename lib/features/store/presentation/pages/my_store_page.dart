import 'package:flutter/material.dart';
import 'package:vendza/core/utils/search/catalog_search.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as detail;
import 'package:vendza/features/notification/data/models/notification_model.dart';
import 'package:vendza/features/notification/data/services/notification_badge_counters.dart';
import 'package:vendza/features/notification/data/services/notification_store.dart';
import 'package:vendza/features/order/data/services/order_api_service.dart';
import 'package:vendza/features/order/presentation/helpers/order_list_presentation.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/order/presentation/pages/buyer_orders_page.dart';
import 'package:vendza/features/store/presentation/pages/add_store_page.dart';
import 'package:vendza/features/store/presentation/pages/my_store_product_page.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/store/presentation/widgets/store_list_section.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/badge/attention_badge.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';
import 'package:vendza/shared/utils/catalog_refresh_feedback.dart';

class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  final _searchController = TextEditingController();
  final _orderApi = OrderApiService();
  String _searchQuery = '';
  Map<String, int> _activeOrderAttentionByStore = const {};
  String _loadedStoreSignature = '';
  bool _loadingStoreAttention = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleStoreAttentionLoad(List<ListStoreModel> stores) {
    final ids = stores
        .map((store) => store.id.trim())
        .where((id) => int.tryParse(id) != null)
        .toList(growable: false);
    final signature = ids.join('|');
    if (signature == _loadedStoreSignature || _loadingStoreAttention) return;
    _loadedStoreSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStoreAttention(ids);
    });
  }

  Future<void> _loadStoreAttention(List<String> storeIds) async {
    if (storeIds.isEmpty) {
      if (mounted) setState(() => _activeOrderAttentionByStore = const {});
      return;
    }
    setState(() => _loadingStoreAttention = true);
    final counts = <String, int>{};
    for (final rawId in storeIds) {
      final storeId = int.tryParse(rawId);
      if (storeId == null) continue;
      try {
        final orders = await _orderApi.storeOrders(
          storeId: storeId,
          pageSize: 100,
        );
        final active = activeOrderAttentionByStore(orders)[storeId] ?? 0;
        if (active > 0) counts[rawId] = active;
      } on Object {
        // Keep the page usable; unread notifications still provide attention.
      }
    }
    if (!mounted) return;
    setState(() {
      _activeOrderAttentionByStore = Map.unmodifiable(counts);
      _loadingStoreAttention = false;
    });
  }

  Map<String, int> _mergedStoreAttention(
    NotificationBadgeCounters counters,
    List<ListStoreModel> stores,
  ) {
    final result = <String, int>{};
    for (final store in stores) {
      final apiCount = _activeOrderAttentionByStore[store.id] ?? 0;
      final unreadCount =
          counters.storeOrdersFor(store.id) +
          counters.storeAttentionFor(store.id);
      final count = apiCount > unreadCount ? apiCount : unreadCount;
      if (count > 0) result[store.id] = count;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VendzaPageHeader.root(
        title: 'Mes Stores',
        subtitle: 'Boutiques, commandes et produits',
        icon: Icons.storefront_outlined,
      ),
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
                    _scheduleStoreAttentionLoad(ownedStores);

                    return RefreshIndicator(
                      onRefresh: () => refreshCatalogWithFeedback(
                        context,
                        targetLabel: "Mes stores",
                        successMessage: "Mes stores sont actualises.",
                      ),
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
                                child:
                                    ValueListenableBuilder<
                                      List<NotificationModel>
                                    >(
                                      valueListenable: notificationStore,
                                      builder: (context, notifications, _) {
                                        final counters =
                                            notificationBadgeCounters(
                                              notifications,
                                            );
                                        final orderCount =
                                            counters.orders +
                                            _activeOrderAttentionByStore.values
                                                .fold<int>(0, (a, b) => a + b);
                                        return ListTile(
                                          tileColor: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          leading: const Icon(
                                            Icons.receipt_long_outlined,
                                          ),
                                          title: const Text('Mes commandes'),
                                          subtitle: const Text(
                                            'Voir les commandes passees',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AttentionBadge(count: orderCount),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.chevron_right),
                                            ],
                                          ),
                                          onTap: () {
                                            markOrderNotificationsAsRead();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const BuyerOrdersPage(),
                                              ),
                                            );
                                          },
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
                                attentionCounts: _mergedStoreAttention(
                                  notificationBadgeCounters(
                                    notificationStore.value,
                                  ),
                                  filteredOwned,
                                ),
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
