import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/utils/search/catalog_search.dart';
import 'package:vendza/features/cathegory/presentation/pages/cathegory_page.dart';
import 'package:vendza/features/collection/presentation/pages/collection_page.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/store/data/services/product_management_service.dart';
import 'package:vendza/features/store/presentation/pages/store_all_products_page.dart';
import 'package:vendza/features/store/presentation/widgets/store_product_toolbar.dart';
import 'package:vendza/shared/models/social_item.dart';
import 'package:vendza/shared/widgets/bouton/text_icon_button.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';
import 'package:vendza/shared/widgets/show_title.dart';

class StoreProductPage extends StatefulWidget {
  const StoreProductPage({super.key, required this.store});

  final StoreModel store;

  @override
  State<StoreProductPage> createState() => _StoreProductPageState();
}

class _StoreProductPageState extends State<StoreProductPage> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchFocusChanged() {
    if (_isSearching == _searchFocusNode.hasFocus) return;
    setState(() {
      _isSearching = _searchFocusNode.hasFocus;
    });
  }

  void _openAllProducts() {
    final visibleProducts = activeProductsForDetailStore(widget.store);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreAllProductsPage(
          title: "Tous les produits",
          products: visibleProducts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: catalogRevision,
      builder: (context, _, _) {
        final List<SocialItem> configuredSocials = configuredStoreSocials();
        final visibleProducts = searchProductsInList(
          _searchQuery,
          activeProductsForDetailStore(widget.store),
        );

        return Scaffold(
          appBar: AppBar(title: Text(widget.store.name)),
          body: RefreshIndicator(
            onRefresh: () => catalogRepository.softRefreshCatalog(force: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  StoreProductToolbar(
                    socials: configuredSocials,
                    isSearching: _isSearching,
                    searchFocusNode: _searchFocusNode,
                    searchController: _searchController,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onSearchTap: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                  const ShowTitle(text: "Filtre", showAction: false),
                  ResponsiveContent(
                    maxWidth: AppBreakpoints.contentMaxWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextIconButton(
                            text: "Categorie",
                            iconData: Icons.category_outlined,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CathegoryPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextIconButton(
                            text: "Collection",
                            iconData: Icons.collections_outlined,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CollectionPage(storeId: widget.store.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  ShowTitle(
                    text: "Tout les produits",
                    onActionTap: _openAllProducts,
                  ),
                  ResponsiveContent(
                    maxWidth: AppBreakpoints.contentMaxWidth,
                    child: ProductSectionWidget(products: visibleProducts),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
