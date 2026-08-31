import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/features/cathegory/data/services/data_exemple.dart'
    as cathegory_data;
import 'package:vendza/features/cathegory/presentation/pages/cathegory_page.dart';
import 'package:vendza/features/collection/data/services/data_exemple.dart'
    as collection_data;
import 'package:vendza/features/collection/presentation/pages/collection_page.dart';
import 'package:vendza/features/product/presentation/pages/product_detail_page.dart';
import 'package:vendza/features/product/presentation/pages/add_product.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/product_management_service.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/order/presentation/pages/store_orders_page.dart';
import 'package:vendza/features/store/presentation/pages/custom_page.dart';
import 'package:vendza/features/store/presentation/widgets/stacked_action_preview.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/bouton/action_button.dart';
import 'package:vendza/shared/widgets/dialog/confirm_delete_dialog.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';
import 'package:vendza/shared/widgets/search/search_bar.dart';

class MyStoreProductPage extends StatefulWidget {
  const MyStoreProductPage({super.key, required this.store});

  final ListStoreModel store;

  @override
  State<MyStoreProductPage> createState() => _MyStoreProductPageState();
}

class _MyStoreProductPageState extends State<MyStoreProductPage>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedProductIds = {};
  late final TabController _catalogTabs;

  bool get _selectionMode => _selectedProductIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _catalogTabs = TabController(length: 2, vsync: this);
    _catalogTabs.addListener(() {
      if (!_catalogTabs.indexIsChanging && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _catalogTabs.dispose();
    super.dispose();
  }

  ListStoreModel get _currentStore {
    final original = widget.store;
    for (final store in ownedStores) {
      if (store.id == original.id) return store;
      if (original.localId.isNotEmpty && store.localId == original.localId) {
        return store;
      }
      if (store.localId == original.id) return store;
    }
    return original;
  }

  bool get _storeSynced => int.tryParse(_currentStore.id) != null;

  List<ProductModel> get _storeProducts => productsForStore(_currentStore);

  bool _isLiveProduct(ProductModel product) {
    return !product.syncStatus.isPending && product.isActive;
  }

  List<ProductModel> get _onlineProducts =>
      _storeProducts.where(_isLiveProduct).toList();

  List<ProductModel> get _offlineProducts =>
      _storeProducts.where((product) => !_isLiveProduct(product)).toList();

  List<ProductModel> get _categoryPreviewProducts {
    final categoryNames = cathegory_data.categories
        .map((category) => category.name)
        .toSet();

    return _storeProducts
        .where((product) => categoryNames.contains(product.category))
        .toList();
  }

  List<ProductModel> get _collectionPreviewProducts {
    return collection_data.collectionProducts.values
        .expand((products) => products)
        .where((product) => product.storeId == _currentStore.id || product.storeId == _currentStore.localId)
        .toList();
  }

  Future<void> _openAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProduct(
          storeId: _currentStore.id,
          storeName: _currentStore.name,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _requireSyncedStore(VoidCallback action) {
    if (_storeSynced) {
      action();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cette action sera disponible une fois la boutique en ligne.',
        ),
      ),
    );
  }

  Future<void> _openSocial(BuildContext context, String? url) async {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir ce lien")),
      );
    }
  }

  Future<void> _openOwnerProduct(ProductModel product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailPage(product: product, ownerMode: true),
      ),
    );
    if (mounted) setState(() {});
  }

  void _toggleProductSelection(ProductModel product) {
    setState(() {
      if (_selectedProductIds.contains(product.id)) {
        _selectedProductIds.remove(product.id);
      } else {
        _selectedProductIds.add(product.id);
      }
    });
  }

  void _selectAllProducts() {
    setState(() {
      final visible = _catalogTabs.index == 1 ? _offlineProducts : _onlineProducts;
      _selectedProductIds
        ..clear()
        ..addAll(visible.map((product) => product.id));
    });
  }

  Future<void> _deleteSelectedProducts() async {
    final count = _selectedProductIds.length;
    final confirmed = await showConfirmDeleteDialog(
      context: context,
      title: "Supprimer les produits",
      message:
          "Es-tu sûr de vouloir supprimer $count produit(s) ? Ils seront aussi retirés des collections.",
    );

    if (!confirmed) return;

    final selectedProducts = _storeProducts
        .where((product) => _selectedProductIds.contains(product.id))
        .toList();

    try {
      for (final product in selectedProducts) {
        await persistManagedProductDelete(product);
      }
      if (!mounted) return;
      setState(() => _selectedProductIds.clear());
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Suppression impossible: $error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: catalogRevision,
      builder: (context, _, _) {
        return Scaffold(
          appBar: _selectionMode
              ? buildSelectionAppBar(
                  context: context,
                  selectedCount: _selectedProductIds.length,
                  onCancel: () => setState(() => _selectedProductIds.clear()),
                  onSelectAll: _selectAllProducts,
                  onDelete: _deleteSelectedProducts,
                )
              : AppBar(title: Text(_currentStore.name)),
          body: Column(
            children: [
              _storeToolbar(context),
              if (!_selectionMode) _storeActions(context),
              Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: TabBar(
                  controller: _catalogTabs,
                  indicatorColor: AppColors.accent(context),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.accent(context),
                  unselectedLabelColor: AppColors.textSecondary(context),
                  tabs: const [
                    Tab(text: 'En ligne'),
                    Tab(text: 'Hors ligne'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _catalogTabs,
                  children: [
                    RefreshIndicator(
                      onRefresh: () =>
                          catalogRepository.softRefreshCatalog(force: true),
                      child: _catalogList(_onlineProducts),
                    ),
                    RefreshIndicator(
                      onRefresh: () =>
                          catalogRepository.softRefreshCatalog(force: true),
                      child: _catalogList(_offlineProducts),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _selectionMode
              ? null
              : FloatingActionButton.extended(
                  onPressed: _openAddProduct,
                  icon: const Icon(Icons.add),
                  label: const Text("Produit"),
                ),
        );
      },
    );
  }

  Widget _storeToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: ResponsiveContent(
        maxWidth: AppBreakpoints.contentMaxWidth,
        child: Row(
          children: [
            const Expanded(child: SearchBarWidget()),
            const SizedBox(width: 20),
            Row(
              children: configuredStoreSocials(_currentStore.id).map((social) {
                final icon = social.gradient != null
                    ? ShaderMask(
                        shaderCallback: (bounds) =>
                            social.gradient!.createShader(bounds),
                        child: FaIcon(
                          social.icon,
                          color: Colors.white,
                          size: 35,
                        ),
                      )
                    : FaIcon(
                        social.icon,
                        color: social.color,
                        size: 35,
                      );
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => _openSocial(context, social.url),
                    child: icon,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: ResponsiveContent(
        maxWidth: AppBreakpoints.contentMaxWidth,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            ActionButton(
              icon: Icons.add_box_outlined,
              label: "Produit",
              onTap: _openAddProduct,
            ),
            ActionButton(
              icon: Icons.category_outlined,
              label: "Catégorie",
              visual: StackedActionPreview(
                products: _categoryPreviewProducts,
                fallbackIcon: Icons.category_outlined,
              ),
              onTap: () async {
                _requireSyncedStore(() async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CathegoryPage(canManage: true),
                    ),
                  );
                  if (mounted) setState(() {});
                });
              },
            ),
            ActionButton(
              icon: Icons.collections_outlined,
              label: "Collection",
              visual: StackedActionPreview(
                products: _collectionPreviewProducts,
                fallbackIcon: Icons.collections_outlined,
              ),
              onTap: () {
                _requireSyncedStore(() async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CollectionPage(
                        storeId: _currentStore.id,
                        canManage: true,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                });
              },
            ),
            ActionButton(
              icon: Icons.receipt_long_outlined,
              label: "Commandes",
              onTap: () {
                _requireSyncedStore(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StoreOrdersPage(store: _currentStore),
                    ),
                  );
                });
              },
            ),
            ActionButton(
              icon: Icons.settings_outlined,
              label: "Custom",
              onTap: () {
                _requireSyncedStore(() async {
                  activateStoreCustomization(_currentStore.id);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomPage(store: _currentStore),
                    ),
                  );
                  if (mounted) setState(() {});
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogList(List<ProductModel> products) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: ProductSectionWidget(
            products: products,
            ownerMode: true,
            showInactiveProducts: true,
            selectionMode: _selectionMode,
            selectedIds: _selectedProductIds,
            onProductTap: _selectionMode
                ? _toggleProductSelection
                : _openOwnerProduct,
            onProductLongPress: _toggleProductSelection,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }
}
