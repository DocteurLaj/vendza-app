import 'package:flutter/material.dart';
import 'package:vendza/core/catalog/catalog_repository.dart'
    show catalogRepository, catalogRevision;
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/home/data/services/data_exemple.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/features/store/presentation/widgets/store_catalog_card.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';

class AllStoresPage extends StatefulWidget {
  const AllStoresPage({super.key});

  @override
  State<AllStoresPage> createState() => _AllStoresPageState();
}

class _AllStoresPageState extends State<AllStoresPage>
    with WidgetsBindingObserver {
  static const int _pageSize = 8;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = "";
  int _visibleCount = _pageSize;
  bool _isSearchMode = false;
  bool _keyboardWasOpen = false;
  DateTime? _searchOpenedAt;

  List<StoreModel> get _filteredStores {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return stores;

    return stores.where((store) {
      return store.name.toLowerCase().contains(normalizedQuery) ||
          store.getDescription().toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  List<StoreModel> get _visibleStores {
    return _filteredStores.take(_visibleCount).toList();
  }

  bool get _canLoadMore => _visibleCount < _filteredStores.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_loadMoreOnScroll);
    _searchFocusNode.addListener(_handleSearchFocusChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchFocusNode
      ..removeListener(_handleSearchFocusChange)
      ..dispose();
    _scrollController
      ..removeListener(_loadMoreOnScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;

    final bottomInset = View.of(context).viewInsets.bottom;
    if (bottomInset > 0) {
      _keyboardWasOpen = true;
      return;
    }

    if (_keyboardWasOpen && _isSearchMode) {
      final openedAt = _searchOpenedAt;
      final openedLongEnough =
          openedAt == null ||
          DateTime.now().difference(openedAt) >
              const Duration(milliseconds: 300);

      if (!openedLongEnough) return;

      _keyboardWasOpen = false;
      _closeSearchMode();
    }
  }

  void _handleSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      _openSearchMode();
    }
  }

  void _openSearchMode() {
    if (_isSearchMode) return;

    setState(() {
      _keyboardWasOpen = false;
      _searchOpenedAt = DateTime.now();
      _isSearchMode = true;
    });
  }

  void _closeSearchMode({bool unfocus = true}) {
    if (!_isSearchMode) return;

    if (unfocus) {
      _searchFocusNode.unfocus();
    }

    setState(() {
      _keyboardWasOpen = false;
      _searchOpenedAt = null;
      _isSearchMode = false;
    });
  }

  void _loadMoreOnScroll() {
    if (!_canLoadMore || !_scrollController.hasClients) return;

    final threshold = _scrollController.position.maxScrollExtent - 140;
    if (_scrollController.offset < threshold) return;

    setState(() {
      final nextVisibleCount = _visibleCount + _pageSize;
      _visibleCount = nextVisibleCount > _filteredStores.length
          ? _filteredStores.length
          : nextVisibleCount;
    });
  }

  void _searchStores(String value) {
    setState(() {
      _query = value;
      _visibleCount = _pageSize;
    });
  }

  void _openStore(StoreModel store) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoreDetailPage(store: store)),
    );
  }

  Future<void> _refreshCatalog() {
    return catalogRepository.softRefreshCatalog(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: catalogRevision,
      builder: (context, _, _) {
        final visibleStores = _visibleStores;

        return PopScope(
          canPop: !_isSearchMode,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _isSearchMode) {
              _closeSearchMode();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.appBackground(context),
            body: Column(
              children: [
                _AnimatedStoresHeader(isSearchMode: _isSearchMode),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: _isSearchMode
                        ? AppColors.isDark(context)
                              ? AppColors.surface(context)
                              : const Color(0xFF0E474A)
                        : Colors.transparent,
                    boxShadow: _isSearchMode
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF073033,
                              ).withValues(alpha: 0.16),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: ResponsiveContent(
                    maxWidth: 820,
                    padding: EdgeInsets.fromLTRB(
                      _isSearchMode ? 12 : 16,
                      _isSearchMode ? 10 : 14,
                      _isSearchMode ? 12 : 16,
                      _isSearchMode ? 14 : 10,
                    ),
                    child: SafeArea(
                      top: _isSearchMode,
                      bottom: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedScale(
                              scale: _isSearchMode ? 1.005 : 1,
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              child: SearchBarWidget(
                                hintText: 'Rechercher une boutique...',
                                focusNode: _searchFocusNode,
                                isActive: _isSearchMode,
                                onTap: _openSearchMode,
                                onChanged: _searchStores,
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _isSearchMode
                                ? Padding(
                                    key: const ValueKey("cancel-search"),
                                    padding: const EdgeInsets.only(left: 8),
                                    child: TextButton(
                                      onPressed: _closeSearchMode,
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            AppColors.isDark(context)
                                            ? AppColors.accent(context)
                                            : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        "Annuler",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey("empty-search-action"),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: _isSearchMode
                      ? const SizedBox.shrink()
                      : ResponsiveContent(
                          maxWidth: 820,
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                          child: _StoreCatalogCounter(
                            visibleCount: visibleStores.length,
                            totalCount: _filteredStores.length,
                          ),
                        ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshCatalog,
                    child: visibleStores.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              _EmptyStoreCatalog(),
                            ],
                          )
                        : ResponsiveContent(
                            maxWidth: 920,
                            child: ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                              itemCount:
                                  visibleStores.length + (_canLoadMore ? 1 : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index >= visibleStores.length) {
                                  return const _LoadMoreHint();
                                }

                                final store = visibleStores[index];
                                return StoreCatalogCard(
                                  store: store,
                                  onTap: () => _openStore(store),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedStoresHeader extends StatelessWidget {
  const _AnimatedStoresHeader({required this.isSearchMode});

  final bool isSearchMode;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final expandedHeight = topPadding + kToolbarHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      height: isSearchMode ? 0 : expandedHeight,
      child: ClipRect(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isSearchMode ? 0 : 1,
          child: Container(
            width: double.infinity,
            color: AppColors.appBackground(context),
            padding: EdgeInsets.only(top: topPadding),
            child: SizedBox(
              width: double.infinity,
              height: kToolbarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 4,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.accent(context),
                      ),
                    ),
                  ),
                  Text(
                    "Tous les stores",
                    style: AppTextStyles.sectionTitle(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreCatalogCounter extends StatelessWidget {
  const _StoreCatalogCounter({
    required this.visibleCount,
    required this.totalCount,
  });

  final int visibleCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Boutiques disponibles",
            style: AppTextStyles.sectionTitle(context),
          ),
        ),
        Text(
          "$visibleCount / $totalCount",
          style: AppTextStyles.label(context),
        ),
      ],
    );
  }
}

class _LoadMoreHint extends StatelessWidget {
  const _LoadMoreHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent(context),
          ),
        ),
      ),
    );
  }
}

class _EmptyStoreCatalog extends StatelessWidget {
  const _EmptyStoreCatalog();

  @override
  Widget build(BuildContext context) {
    return const ResponsiveContent(
      maxWidth: 720,
      child: Center(
        child: EmptyStateWidget(
          icon: Icons.storefront_outlined,
          title: "Aucune boutique trouvée",
          message: "Essaie avec un autre nom ou vérifie l'orthographe.",
        ),
      ),
    );
  }
}
