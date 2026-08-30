import 'package:flutter/material.dart';
import 'package:vendza/core/catalog/catalog_repository.dart'
    show catalogRepository, catalogRevision;
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/sizes.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/home/data/services/data_exemple.dart';
import 'package:vendza/features/home/presantation/pages/home_product_list_page.dart';
import 'package:vendza/features/home/presantation/widgets/home_search_filter_bar.dart';
import 'package:vendza/features/product/presentation/pages/product_detail_page.dart';
import 'package:vendza/features/store/presentation/pages/all_stores_page.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/subscription/presentation/pages/subscription_page.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/carousel/animated_circular_ring.dart';
import 'package:vendza/shared/widgets/carousel/auto_scroll_carousel.dart';
import 'package:vendza/shared/widgets/carousel/carousel_scroll_scope.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';
import 'package:vendza/shared/widgets/product/product_price_text.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';
import 'package:vendza/shared/widgets/show_title.dart';
import 'package:vendza/shared/widgets/store/store_section.dart';

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

List<StoreModel> _homeStoreRail(List<StoreModel> featured, {int limit = 8}) {
  final result = <StoreModel>[];
  final seen = <String>{};
  void add(StoreModel store) {
    final key = store.id.isNotEmpty ? store.id : store.name;
    if (key.isEmpty || !seen.add(key)) return;
    result.add(store);
  }

  for (final store in featured) {
    add(store);
  }
  for (final store in homeStores) {
    if (result.length >= limit) break;
    add(store);
  }
  return result;
}

List<ProductModel> _activeCatalogProducts() {
  return homeProducts.where((product) => product.isActive).toList();
}

List<ProductModel> _takeUnused(
  List<ProductModel> source,
  Set<String> usedIds, {
  int? limit,
}) {
  final unused = source
      .where((product) => !usedIds.contains(product.id))
      .toList();
  if (limit == null) return unused;
  return unused.take(limit).toList();
}

List<ProductModel> _fillHomeSection(
  List<ProductModel> feed,
  List<ProductModel> catalog,
  Set<String> usedIds, {
  int? limit,
  bool allowReuse = false,
}) {
  if (feed.isNotEmpty) return feed;
  final unused = _takeUnused(catalog, usedIds, limit: limit);
  if (unused.isNotEmpty) return unused;
  if (!allowReuse || catalog.isEmpty) return const [];
  if (limit == null) return List<ProductModel>.from(catalog);
  return catalog.take(limit).toList();
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: AppBar(
              leading: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _isSearching
                    ? IconButton(
                        key: const ValueKey("close-search"),
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.accent(context),
                        ),
                        onPressed: _closeSearch,
                      )
                    : _PremiumButton(
                        key: const ValueKey("premium-button"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SubscriptionPage(),
                            ),
                          );
                        },
                      ),
              ),
              backgroundColor: AppColors.appBackground(context),
              elevation: 0,
              title: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(
                  _isSearching ? -6 : 0,
                  0,
                  0,
                ),
                child: ResponsiveContent(
                  maxWidth: 720,
                  child: SearchBarWidget(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    hintText: 'Rechercher produits ou stores...',
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
                    onSubmitted: (_) {},
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

class _PremiumButton extends StatelessWidget {
  const _PremiumButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AppInteractive(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(126, 255, 193, 7),
                Color.fromARGB(214, 255, 153, 0),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.workspace_premium, color: Colors.white),
        ),
      ),
    );
  }
}

class _HomeDefaultContent extends StatefulWidget {
  const _HomeDefaultContent({super.key});

  @override
  State<_HomeDefaultContent> createState() => _HomeDefaultContentState();
}

class _HomeDefaultContentState extends State<_HomeDefaultContent> {
  static const int _initialVisibleProducts = 16;
  static const int _productsPerLoad = 8;
  static const double _discoverTileExtent = 154;

  final ScrollController _scrollController = ScrollController();
  final ScrollController _discoverRailController = ScrollController();
  int _visibleProductCount = _initialVisibleProducts;
  bool _isLoadingMore = false;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _discoverRailController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final shouldShowBackToTop = position.pixels > 520;
    if (shouldShowBackToTop != _showBackToTop) {
      setState(() => _showBackToTop = shouldShowBackToTop);
    }

    if (_isLoadingMore) return;
    if (position.pixels < position.maxScrollExtent - 260) return;

    _loadMoreProducts(animateToNewItems: false);
  }

  Future<void> _loadMoreProducts({bool animateToNewItems = true}) async {
    final discoverProducts = homeFeed.discoverProducts;
    if (_visibleProductCount >= discoverProducts.length) return;
    final previousVisibleCount = _visibleProductCount;

    setState(() => _isLoadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    setState(() {
      _visibleProductCount = (_visibleProductCount + _productsPerLoad).clamp(
        0,
        discoverProducts.length,
      );
      _isLoadingMore = false;
    });

    if (animateToNewItems) {
      _scrollDiscoverRailToIndex(previousVisibleCount);
      _scrollPageTowardNewItems();
    }
  }

  void _scrollDiscoverRailToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_discoverRailController.hasClients) return;

      final targetOffset = (index * _discoverTileExtent).clamp(
        0,
        _discoverRailController.position.maxScrollExtent,
      );
      _discoverRailController.animateTo(
        targetOffset.toDouble(),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _scrollPageTowardNewItems() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final targetOffset = (_scrollController.offset + 420).clamp(
        0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset.toDouble(),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _scrollToTop() async {
    if (_discoverRailController.hasClients) {
      _discoverRailController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    }

    if (mounted && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = HomeSectionsView(homeFeed);
    final featuredStores = _homeStoreRail(sections.stores);
    final catalogProducts = _activeCatalogProducts();
    final usedProductIds = <String>{};
    final promotionProducts = _fillHomeSection(
      sections.tendances,
      catalogProducts,
      usedProductIds,
      limit: 8,
    );
    usedProductIds.addAll(promotionProducts.map((product) => product.id));
    final storyProducts = _fillHomeSection(
      sections.newest,
      catalogProducts,
      usedProductIds,
      limit: 8,
    );
    usedProductIds.addAll(storyProducts.map((product) => product.id));
    final popularProducts = _fillHomeSection(
      sections.popular,
      catalogProducts,
      usedProductIds,
      limit: 8,
      allowReuse: true,
    );
    usedProductIds.addAll(popularProducts.map((product) => product.id));
    final discoverProducts = _fillHomeSection(
      sections.discover,
      catalogProducts,
      usedProductIds,
      allowReuse: true,
    );
    final featuredFeedIds = sections.stores
        .map((store) => store.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    final discoverStores = homeStores
        .where((store) => !featuredFeedIds.contains(store.id))
        .take(8)
        .toList();
    final visibleDiscoverProducts = discoverProducts
        .take(_visibleProductCount)
        .toList();
    final horizontalDiscoverProducts = visibleDiscoverProducts
        .take(12)
        .toList();
    final verticalDiscoverProducts = visibleDiscoverProducts.skip(4).toList();
    final canLoadMore = _visibleProductCount < discoverProducts.length;

    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: () => catalogRepository.softRefreshCatalog(force: true),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: ResponsiveContent(
                maxWidth: 920,
                child: Column(
                  spacing: AppSizes.padding,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (featuredStores.isNotEmpty) ...[
                      ShowTitle(
                        text: "Stores",
                        onActionTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllStoresPage(),
                            ),
                          );
                        },
                      ),
                      StoreSectionWidget(stores: featuredStores),
                    ],
                    if (promotionProducts.isNotEmpty) ...[
                      ShowTitle(
                        text: "Tendances",
                        onActionTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeProductListPage(
                                title: "Tendances",
                                products: promotionProducts,
                                section: 'trending',
                              ),
                            ),
                          );
                        },
                      ),
                      _PromotionCarousel(products: promotionProducts),
                    ],
                    if (storyProducts.isNotEmpty)
                      _StoryProductsStrip(products: storyProducts),
                    if (discoverStores.isNotEmpty) ...[
                      ShowTitle(
                        text: "Decouvrir des stores",
                        actionLabel: "Voir tout le store",
                        onActionTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllStoresPage(),
                            ),
                          );
                        },
                      ),
                      _StoreDiscoveryRail(stores: discoverStores),
                    ],
                    if (popularProducts.isNotEmpty) ...[
                      ShowTitle(text: "Articles Populaires", showAction: false),
                      ProductSectionWidget(
                        products: popularProducts,
                        onProductTap: (product) {
                          openHomeProduct(
                            context,
                            product,
                            section: 'popular',
                            position: popularProducts.indexOf(product),
                          );
                        },
                      ),
                    ],
                    if (discoverProducts.isNotEmpty) ...[
                      ShowTitle(text: "Decouvrir aussi", showAction: false),
                      _TrendingRail(
                        products: horizontalDiscoverProducts,
                        controller: _discoverRailController,
                      ),
                    ],
                    if (verticalDiscoverProducts.isNotEmpty)
                      _ProgressiveDiscoverSections(
                        products: verticalDiscoverProducts,
                        stores: discoverStores,
                        promoProducts: promotionProducts,
                      ),
                    if (canLoadMore || _isLoadingMore)
                      _LoadMoreProductsButton(
                        isLoading: _isLoadingMore,
                        onPressed: () => _loadMoreProducts(),
                      ),
                    const SizedBox(height: 78),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
          child: _BackToTopButton(
            visible: _showBackToTop,
            onPressed: _scrollToTop,
          ),
        ),
      ],
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  const _BackToTopButton({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: visible ? 1 : 0.86,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AppInteractive(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(23),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromotionCarousel extends StatefulWidget {
  const _PromotionCarousel({required this.products});

  final List<ProductModel> products;

  @override
  State<_PromotionCarousel> createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<_PromotionCarousel> {
  late final PageController _controller;
  AutoScrollPageHelper? _autoScroll;
  int _currentPage = 1000;

  int get _itemCount => widget.products.length;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.86,
      initialPage: _currentPage,
    );
    if (_itemCount > 1) {
      _autoScroll = AutoScrollPageHelper(
        controller: _controller,
        itemCount: _itemCount,
        initialPage: _currentPage,
        initialDelay: const Duration(milliseconds: 400),
        onVirtualPageChanged: (page) {
          if (mounted) setState(() => _currentPage = page);
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoScroll?.startAfterLayout();
      });
    }
  }

  @override
  void dispose() {
    _autoScroll?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: CarouselScrollScope(
            onUserScrollStart: () => _autoScroll?.onUserScrollStart(),
            onUserScrollEnd: () => _autoScroll?.onUserScrollEnd(),
            child: PageView.builder(
              controller: _controller,
              itemCount: _itemCount > 1 ? null : _itemCount,
              onPageChanged: (index) {
                _autoScroll?.updateCurrentPage(index);
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final product = widget.products[index % _itemCount];

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double scale = 1;
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      final page = _controller.page ?? _currentPage.toDouble();
                      scale = (1 - (page - index).abs() * 0.08)
                          .clamp(0.92, 1.0)
                          .toDouble();
                    }

                    return Transform.scale(scale: scale, child: child);
                  },
                  child: _PromotionCard(
                    product: product,
                    index: index % _itemCount,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        CarouselCircularDots(
          count: _itemCount,
          activeIndex: _currentPage % _itemCount,
          onDotTap: _itemCount > 1
              ? (index) => _autoScroll?.goToItemIndex(index)
              : null,
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.product, required this.index});

  final ProductModel product;
  final int index;

  @override
  Widget build(BuildContext context) {
    final imagePath = product.imageurl.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: AppInteractive(
        onTap: () {
          openHomeProduct(
            context,
            product,
            section: 'trending',
            position: index,
          );
        },
        borderRadius: BorderRadius.circular(18),
        enableHoverElevation: true,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath.isNotEmpty)
                SmartImage(
                  path: imagePath,
                  fit: BoxFit.cover,
                  errorWidget: const SizedBox.shrink(),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: _RankBadge(label: "Selection"),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.storeName.trim().isEmpty
                                ? "Produit demande"
                                : product.storeName.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFEAF2EF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Flexible(
                          child: ProductPriceText(
                            product.price,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface(context).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTextStyles.label(context).copyWith(
          color: AppColors.cardTitle(context),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StoreDiscoveryRail extends StatefulWidget {
  const _StoreDiscoveryRail({required this.stores});

  final List<StoreModel> stores;

  @override
  State<_StoreDiscoveryRail> createState() => _StoreDiscoveryRailState();
}

class _StoreDiscoveryRailState extends State<_StoreDiscoveryRail> {
  static const double _itemExtent = 168;

  late final ScrollController _scrollController;
  late final AutoScrollListHelper _autoScroll;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _autoScroll = AutoScrollListHelper(
      scrollController: _scrollController,
      itemCount: widget.stores.length,
      itemExtent: _itemExtent,
      initialDelay: const Duration(milliseconds: 1400),
      onIndexChanged: (index) {
        if (mounted) setState(() => _activeIndex = index);
      },
    )..attachListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoScroll.startAfterLayout();
    });
  }

  @override
  void dispose() {
    _autoScroll.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stores.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: CarouselScrollScope(
            onUserScrollStart: _autoScroll.onUserScrollStart,
            onUserScrollEnd: _autoScroll.onUserScrollEnd,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: carouselListPhysics,
              padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
              itemCount: widget.stores.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _StoreDiscoveryCard(
                  store: widget.stores[index],
                  index: index,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        CarouselCircularDots(
          count: widget.stores.length,
          activeIndex: _activeIndex,
          onDotTap: widget.stores.length > 1 ? _autoScroll.goToIndex : null,
        ),
      ],
    );
  }
}

class _StoreDiscoveryCard extends StatelessWidget {
  const _StoreDiscoveryCard({required this.store, required this.index});

  final StoreModel store;
  final int index;

  @override
  Widget build(BuildContext context) {
    final imagePath = store.image.trim();
    final accentColors = [
      AppColors.softSurface(context),
      AppColors.elevatedSurface(context),
      AppColors.card(context),
    ];
    final backgroundColor = accentColors[index % accentColors.length];

    return AppInteractive(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailPage(store: store),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      enableHoverElevation: true,
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: imagePath.isEmpty
                        ? const _StoreDiscoveryPlaceholder()
                        : SmartImage(
                            path: imagePath,
                            fit: BoxFit.cover,
                            errorWidget: const _StoreDiscoveryPlaceholder(),
                          ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.card(context).withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.iconAccent(context),
                    size: 13,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              "Decouvrir",
              style: AppTextStyles.label(context).copyWith(fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              store.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle(
                context,
              ).copyWith(fontSize: 15, height: 1.12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreDiscoveryPlaceholder extends StatelessWidget {
  const _StoreDiscoveryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card(context).withValues(alpha: 0.68),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        color: AppColors.iconAccent(context),
      ),
    );
  }
}

class _StoryProductsStrip extends StatefulWidget {
  const _StoryProductsStrip({required this.products});

  final List<ProductModel> products;

  @override
  State<_StoryProductsStrip> createState() => _StoryProductsStripState();
}

class _StoryProductsStripState extends State<_StoryProductsStrip> {
  static const double _itemExtent = 86;

  late final ScrollController _scrollController;
  AutoScrollListHelper? _autoScroll;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.products.length > 1) {
      _autoScroll = AutoScrollListHelper(
        scrollController: _scrollController,
        itemCount: widget.products.length,
        itemExtent: _itemExtent,
        initialDelay: const Duration(milliseconds: 900),
        onIndexChanged: (index) {
          if (mounted) setState(() => _activeIndex = index);
        },
      )..attachListener();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoScroll?.startAfterLayout();
      });
    }
  }

  @override
  void dispose() {
    _autoScroll?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 104,
          child: CarouselScrollScope(
            onUserScrollStart: () => _autoScroll?.onUserScrollStart(),
            onUserScrollEnd: () => _autoScroll?.onUserScrollEnd(),
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: carouselListPhysics,
              padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
              itemCount: widget.products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _StoryProductBubble(
                  product: widget.products[index],
                  index: index,
                );
              },
            ),
          ),
        ),
        if (widget.products.length > 1) ...[
          const SizedBox(height: 8),
          CarouselCircularDots(
            count: widget.products.length.clamp(0, 8),
            activeIndex: _activeIndex % widget.products.length.clamp(1, 8),
            onDotTap: (index) => _autoScroll?.goToIndex(index),
          ),
        ],
      ],
    );
  }
}

class _StoryProductBubble extends StatelessWidget {
  const _StoryProductBubble({required this.product, required this.index});

  final ProductModel product;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: () {
        openHomeProduct(context, product, section: 'newest', position: index);
      },
      borderRadius: BorderRadius.circular(35),
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            AnimatedCircularRing(
              size: 70,
              child: product.imageurl.trim().isEmpty
                  ? const _DynamicProductPlaceholder()
                  : SizedBox.expand(
                      child: SmartImage(
                        path: product.imageurl,
                        fit: BoxFit.cover,
                        errorWidget: const _DynamicProductPlaceholder(),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.label(context).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingRail extends StatefulWidget {
  const _TrendingRail({required this.products, required this.controller});

  final List<ProductModel> products;
  final ScrollController controller;

  @override
  State<_TrendingRail> createState() => _TrendingRailState();
}

class _TrendingRailState extends State<_TrendingRail> {
  static const double _itemExtent = 154;

  AutoScrollListHelper? _autoScroll;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.products.length > 1) {
      _autoScroll = AutoScrollListHelper(
        scrollController: widget.controller,
        itemCount: widget.products.length,
        itemExtent: _itemExtent,
        initialDelay: const Duration(milliseconds: 1900),
        onIndexChanged: (index) {
          if (mounted) setState(() => _activeIndex = index);
        },
      )..attachListener();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoScroll?.startAfterLayout();
      });
    }
  }

  @override
  void dispose() {
    _autoScroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 156,
          child: CarouselScrollScope(
            onUserScrollStart: () => _autoScroll?.onUserScrollStart(),
            onUserScrollEnd: () => _autoScroll?.onUserScrollEnd(),
            child: ListView.separated(
              controller: widget.controller,
              scrollDirection: Axis.horizontal,
              physics: carouselListPhysics,
              padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
              itemCount: widget.products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _TrendingMiniCard(
                  product: widget.products[index],
                  index: index,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        CarouselCircularDots(
          count: widget.products.length,
          activeIndex: _activeIndex,
          onDotTap: widget.products.length > 1
              ? (index) => _autoScroll?.goToIndex(index)
              : null,
        ),
      ],
    );
  }
}

class _ProgressiveDiscoverSections extends StatelessWidget {
  const _ProgressiveDiscoverSections({
    required this.products,
    this.stores = const [],
    this.promoProducts = const [],
  });

  static const int _gridChunkSize = 10;
  static const int _horizontalChunkSize = 6;

  final List<ProductModel> products;
  final List<StoreModel> stores;
  final List<ProductModel> promoProducts;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final sections = <Widget>[];
    int startIndex = 0;
    int horizontalSectionIndex = 0;
    var insertedStores = false;
    var insertedPromos = false;

    while (startIndex < products.length) {
      final gridEnd = (startIndex + _gridChunkSize).clamp(0, products.length);
      final gridProducts = products.sublist(startIndex, gridEnd);
      if (gridProducts.isNotEmpty) {
        sections.add(
          ProductSectionWidget(
            products: gridProducts,
            onProductTap: (product) {
              openHomeProduct(
                context,
                product,
                section: 'discover',
                position: products.indexOf(product),
              );
            },
          ),
        );
      }
      startIndex = gridEnd;

      if (!insertedStores && stores.isNotEmpty && gridProducts.isNotEmpty) {
        insertedStores = true;
        sections.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.padding + 8,
                  ),
                  child: Text(
                    "Decouvrir des stores",
                    style: AppTextStyles.sectionTitle(
                      context,
                    ).copyWith(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 8),
                _StoreDiscoveryRail(stores: stores),
              ],
            ),
          ),
        );
      }

      if (startIndex >= products.length) break;

      final horizontalEnd = (startIndex + _horizontalChunkSize).clamp(
        0,
        products.length,
      );
      final horizontalProducts = products.sublist(startIndex, horizontalEnd);
      if (horizontalProducts.isNotEmpty) {
        horizontalSectionIndex++;
        sections.add(
          _InlineDiscoverRail(
            products: horizontalProducts,
            sectionIndex: horizontalSectionIndex,
          ),
        );
      }
      startIndex = horizontalEnd;

      if (!insertedPromos &&
          promoProducts.isNotEmpty &&
          startIndex < products.length) {
        insertedPromos = true;
        sections.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: _PromotionCarousel(products: promoProducts),
          ),
        );
      }
    }

    return Column(children: sections);
  }
}

class _InlineDiscoverRail extends StatelessWidget {
  const _InlineDiscoverRail({
    required this.products,
    required this.sectionIndex,
  });

  final List<ProductModel> products;
  final int sectionIndex;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.padding + 8),
            child: Text(
              sectionIndex.isOdd ? "Selection rapide" : "A ne pas manquer",
              style: AppTextStyles.sectionTitle(
                context,
              ).copyWith(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _TrendingMiniCard(
                  product: products[index],
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingMiniCard extends StatelessWidget {
  const _TrendingMiniCard({required this.product, this.index = 0});

  final ProductModel product;
  final int index;

  @override
  Widget build(BuildContext context) {
    final imagePath = product.imageurl.trim();

    return AppInteractive(
      onTap: () {
        openHomeProduct(context, product, section: 'discover', position: index);
      },
      borderRadius: BorderRadius.circular(16),
      enableHoverElevation: true,
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: AppColors.isDark(context) ? 0.12 : 0.04,
              ),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imagePath.isEmpty
                        ? const _DynamicProductPlaceholder()
                        : SmartImage(
                            path: imagePath,
                            fit: BoxFit.cover,
                            errorWidget: const _DynamicProductPlaceholder(),
                          ),
                    Positioned(
                      top: 7,
                      left: 7,
                      child: _RankBadge(label: "A voir"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle(context).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 3),
            if (product.storeName.trim().isEmpty)
              ProductPriceText(
                product.price,
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.success(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              Text(
                product.storeName.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.success(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadMoreProductsButton extends StatelessWidget {
  const _LoadMoreProductsButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.expand_more_rounded),
          label: Text(
            isLoading ? "Chargement..." : "Voir plus de produits",
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicProductPlaceholder extends StatelessWidget {
  const _DynamicProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSurface(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.accent(context),
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
