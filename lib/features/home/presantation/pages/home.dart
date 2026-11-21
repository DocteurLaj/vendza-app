import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/catalog/catalog_repository.dart'
    show catalogError, catalogLoading, catalogRepository, catalogRevision;
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/search_event_api_service.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/home/data/services/data_exemple.dart';
import 'package:vendza/features/home/presantation/pages/home_product_list_page.dart';
import 'package:vendza/features/home/presantation/widgets/home_search_filter_bar.dart';
import 'package:vendza/features/home/presantation/widgets/balade_home.dart';
import 'package:vendza/features/product/presentation/pages/product_detail_page.dart';
import 'package:vendza/features/profil/presantation/pages/profile_page.dart';
import 'package:vendza/features/store/presentation/pages/all_stores_page.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/subscription/presentation/pages/subscription_page.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';
import 'package:vendza/shared/widgets/product/product_price_text.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';

void openHomeProduct(
  BuildContext context,
  ProductModel product, {
  String? section,
  int? position,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductDetailPage(
        product: product,
        section: section,
        position: position,
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = "";
  bool _isSearching = false;
  HomeSearchFilter _searchFilter = HomeSearchFilter.all;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          homeStores.isEmpty &&
          homeProducts.isEmpty &&
          !catalogLoading.value) {
        unawaited(catalogRepository.softRefreshCatalog(force: true));
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool get _hasActiveSearch =>
      _searchFocusNode.hasFocus || _query.trim().isNotEmpty;

  void _syncSearchMode() {
    final shouldSearch = _hasActiveSearch;
    if (shouldSearch == _isSearching) return;
    setState(() => _isSearching = shouldSearch);
  }

  void _handleSearchFocusChanged() {
    _syncSearchMode();
  }

  void _closeSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _query = "";
      _isSearching = false;
      _searchFilter = HomeSearchFilter.all;
    });
  }

  List<ProductModel> get _matchingProducts {
    final query = _normalize(_query);
    if (query.isEmpty) return const [];

    return products.where((product) {
      if (!product.isActive) return false;
      return _matches(query, [
        product.name,
        product.category,
        product.description,
        product.storeName,
        product.price,
      ]);
    }).toList();
  }

  List<StoreModel> get _matchingStores {
    final query = _normalize(_query);
    if (query.isEmpty) return const [];

    return stores.where((store) {
      return _matches(query, [store.name, store.getDescription()]);
    }).toList();
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  bool _matches(String query, List<String> values) {
    return values.any((value) => _normalize(value).contains(query));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: catalogRevision,
      builder: (context, _, child) {
        return Scaffold(
          backgroundColor: AppColors.isDark(context)
              ? AppColors.appBackground(context)
              : const Color(0xFFFAF8F3),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(118),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 660),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 53,
                          child: Row(
                            children: [
                              if (_isSearching)
                                IconButton(
                                  tooltip: 'Fermer la recherche',
                                  onPressed: _closeSearch,
                                  icon: const Icon(Icons.arrow_back),
                                ),
                              Expanded(
                                child: Text(
                                  'vendza.',
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Voir les abonnements',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SubscriptionPage(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.workspace_premium_outlined,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Ouvrir le profil',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfilePage(),
                                  ),
                                ),
                                icon: const Icon(Icons.person_outline),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        SearchBarWidget(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          hintText: 'Rechercher un article ou une boutique',
                          isActive: _isSearching,
                          onChanged: (value) => setState(() {
                            _query = value;
                            _isSearching = true;
                          }),
                          onClear: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _searchFilter = HomeSearchFilter.all;
                              _isSearching = _hasActiveSearch;
                            });
                          },
                          onSubmitted: (query) {
                            if (query.trim().length < 2 ||
                                !apiTokenStore.hasAccessToken) {
                              return;
                            }
                            unawaited(
                              Future(() async {
                                try {
                                  await searchEventApiService.track(
                                    query,
                                    resultsCount:
                                        _matchingProducts.length +
                                        _matchingStores.length,
                                  );
                                  await catalogRepository.softRefreshCatalog(
                                    force: true,
                                  );
                                } catch (_) {
                                  // Local search remains available offline.
                                }
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _isSearching
                ? _HomeSearchResults(
                    key: const ValueKey("home-search-results"),
                    query: _query,
                    products: _matchingProducts,
                    stores: _matchingStores,
                    filter: _searchFilter,
                    onFilterChanged: (filter) =>
                        setState(() => _searchFilter = filter),
                  )
                : const _HomeDefaultContent(
                    key: ValueKey("home-default-content"),
                  ),
          ),
        );
      },
    );
  }
}

class _HomeDefaultContent extends StatelessWidget {
  const _HomeDefaultContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: catalogLoading,
      builder: (context, loading, _) => BaladeHome(
        feed: homeFeed,
        catalogProducts: homeProducts,
        catalogStores: homeStores,
        loading: loading,
        error: catalogError.value,
        onRefresh: () => catalogRepository.softRefreshCatalog(force: true),
        onProductTap: (product) =>
            openHomeProduct(context, product, section: 'discover'),
        onStoreTap: (store) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoreDetailPage(store: store)),
        ),
        onAllProducts: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeProductListPage(
              title: homeFeed.personalized ? 'Pour vous' : 'À découvrir',
              products: homeFeed.rankedProducts(homeProducts),
              section: 'discover',
            ),
          ),
        ),
        onAllStores: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AllStoresPage()),
        ),
      ),
    );
  }
}

class _HomeSearchResults extends StatelessWidget {
  const _HomeSearchResults({
    super.key,
    required this.query,
    required this.products,
    required this.stores,
    required this.filter,
    required this.onFilterChanged,
  });

  final String query;
  final List<ProductModel> products;
  final List<StoreModel> stores;
  final HomeSearchFilter filter;
  final ValueChanged<HomeSearchFilter> onFilterChanged;

  static const _filterAnimationDuration = Duration(milliseconds: 280);

  static Widget _filterTransitionBuilder(
    Widget child,
    Animation<double> animation,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return const _SearchEmptyHint();
    }

    if (products.isEmpty && stores.isEmpty) {
      return _SearchNoResults(query: trimmedQuery);
    }

    final isProductsFilterEmpty =
        filter == HomeSearchFilter.products && products.isEmpty;
    final isStoresFilterEmpty =
        filter == HomeSearchFilter.stores && stores.isEmpty;

    final contentKey = isProductsFilterEmpty
        ? const ValueKey('filter-empty-products')
        : isStoresFilterEmpty
        ? const ValueKey('filter-empty-stores')
        : ValueKey(filter);

    return ResponsiveContent(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          HomeSearchFilterBar(
            selected: filter,
            onChanged: onFilterChanged,
            productCount: products.length,
            storeCount: stores.length,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: _filterAnimationDuration,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: _filterTransitionBuilder,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [...previousChildren, ?currentChild],
              );
            },
            child: KeyedSubtree(
              key: contentKey,
              child: _FilteredSearchContent(
                query: trimmedQuery,
                products: products,
                stores: stores,
                filter: filter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredSearchContent extends StatelessWidget {
  const _FilteredSearchContent({
    required this.query,
    required this.products,
    required this.stores,
    required this.filter,
  });

  final String query;
  final List<ProductModel> products;
  final List<StoreModel> stores;
  final HomeSearchFilter filter;

  @override
  Widget build(BuildContext context) {
    if (filter == HomeSearchFilter.products && products.isEmpty) {
      return _SearchFilterEmptyContent(query: query, label: 'produit');
    }

    if (filter == HomeSearchFilter.stores && stores.isEmpty) {
      return _SearchFilterEmptyContent(query: query, label: 'store');
    }

    final showProducts =
        filter == HomeSearchFilter.all || filter == HomeSearchFilter.products;
    final showStores =
        filter == HomeSearchFilter.all || filter == HomeSearchFilter.stores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchSummary(
          query: query,
          productCount: products.length,
          storeCount: stores.length,
        ),
        if (showProducts && products.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _SearchSectionTitle(
            title: "Produits",
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 8),
          ...products.map((product) => _ProductResultTile(product: product)),
        ],
        if (showStores && stores.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SearchSectionTitle(
            title: "Stores",
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 8),
          ...stores.map((store) => _StoreResultTile(store: store)),
        ],
      ],
    );
  }
}

class _SearchEmptyHint extends StatelessWidget {
  const _SearchEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.accent(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.manage_search_rounded,
                color: AppColors.iconAccent(context),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Rechercher dans Vendza",
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context),
            ),
            const SizedBox(height: 7),
            Text(
              "Tapez le nom d'un produit, d'une categorie ou d'un store.",
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(fontSize: 13, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchNoResults extends StatelessWidget {
  const _SearchNoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: AppColors.iconAccent(context),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun resultat pour "$query"',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageTitle(context).copyWith(fontSize: 17),
            ),
            const SizedBox(height: 7),
            Text(
              "Essayez avec un autre nom de produit ou de boutique.",
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle(
                context,
              ).copyWith(fontSize: 13, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFilterEmptyContent extends StatelessWidget {
  const _SearchFilterEmptyContent({required this.query, required this.label});

  final String query;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 40, 14, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppColors.iconAccent(context),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun $label pour "$query"',
            textAlign: TextAlign.center,
            style: AppTextStyles.pageTitle(context).copyWith(fontSize: 17),
          ),
          const SizedBox(height: 7),
          Text(
            'Essayez un autre filtre ou modifiez votre recherche.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle(
              context,
            ).copyWith(fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SearchSummary extends StatelessWidget {
  const _SearchSummary({
    required this.query,
    required this.productCount,
    required this.storeCount,
  });

  final String query;
  final int productCount;
  final int storeCount;

  @override
  Widget build(BuildContext context) {
    final int total = productCount + storeCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.iconAccent(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$total resultat(s) pour "$query"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  const _SearchSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.iconAccent(context), size: 18),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ProductResultTile extends StatelessWidget {
  const _ProductResultTile({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return _SearchResultShell(
      onTap: () {
        openHomeProduct(context, product, section: 'search');
      },
      image: _ResultImage(
        imageUrl: product.imageurl,
        fallbackIcon: Icons.inventory_2_outlined,
      ),
      title: product.name,
      subtitle: product.storeName.trim().isEmpty
          ? product.category
          : product.storeName.trim(),
      trailing: ProductPriceText(
        product.price,
        textAlign: TextAlign.right,
        currencyFirstBelowWidth: 86,
        style: AppTextStyles.label(context).copyWith(
          color: AppColors.success(context),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StoreResultTile extends StatelessWidget {
  const _StoreResultTile({required this.store});

  final StoreModel store;

  @override
  Widget build(BuildContext context) {
    return _SearchResultShell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailPage(store: store),
          ),
        );
      },
      image: _ResultImage(
        imageUrl: store.image,
        fallbackIcon: Icons.storefront_outlined,
      ),
      title: store.name,
      subtitle: store.getDescription(),
      trailing: Text(
        "Store",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: AppTextStyles.label(context).copyWith(
          color: AppColors.success(context),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SearchResultShell extends StatelessWidget {
  const _SearchResultShell({
    required this.onTap,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final VoidCallback onTap;
  final Widget image;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppInteractive(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        enableHoverElevation: true,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: AppColors.isDark(context) ? 0.12 : 0.035,
                ),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              image,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle(
                        context,
                      ).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle.trim().isEmpty ? "Vendza" : subtitle.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle(
                        context,
                      ).copyWith(height: 1.25, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.imageUrl, required this.fallbackIcon});

  final String imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final path = imageUrl.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: SizedBox(
        width: 58,
        height: 58,
        child: path.isEmpty
            ? _ResultImagePlaceholder(icon: fallbackIcon)
            : SmartImage(
                path: path,
                fit: BoxFit.cover,
                errorWidget: _ResultImagePlaceholder(icon: fallbackIcon),
              ),
      ),
    );
  }
}

class _ResultImagePlaceholder extends StatelessWidget {
  const _ResultImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSurface(context),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.accent(context), size: 24),
    );
  }
}
