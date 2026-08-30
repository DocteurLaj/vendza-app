import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/features/order/presentation/pages/store_orders_page.dart';
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

class _MyStoreProductPageState extends State<MyStoreProductPage> {
  final Set<String> _selectedProductIds = {};

  bool get _selectionMode => _selectedProductIds.isNotEmpty;

  List<ProductModel> get _storeProducts => productsForStore(widget.store);

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
        .where((product) => product.storeId == widget.store.id)
        .toList();
  }

  Future<void> _openAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddProduct(storeId: widget.store.id, storeName: widget.store.name),
      ),
    );
    if (mounted) setState(() {});
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
      _selectedProductIds
        ..clear()
        ..addAll(_storeProducts.map((product) => product.id));
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
              : AppBar(title: Text(widget.store.name)),
          body: RefreshIndicator(
            onRefresh: () => catalogRepository.softRefreshCatalog(force: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  ResponsiveContent(
                    maxWidth: AppBreakpoints.contentMaxWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Expanded(child: SearchBarWidget()),
                        const SizedBox(width: 20),
                        Row(
                          children: configuredStoreSocials(widget.store.id).map((
                            social,
                          ) {
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
                  const SizedBox(height: 20),
                  if (!_selectionMode)
                    ResponsiveContent(
                      maxWidth: AppBreakpoints.contentMaxWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CathegoryPage(canManage: true),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                          ActionButton(
                            icon: Icons.collections_outlined,
                            label: "Collection",
                            visual: StackedActionPreview(
                              products: _collectionPreviewProducts,
                              fallbackIcon: Icons.collections_outlined,
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CollectionPage(
                                    storeId: widget.store.id,
                                    canManage: true,
                                  ),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                          ActionButton(
                            icon: Icons.receipt_long_outlined,
                            label: "Commandes",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      StoreOrdersPage(store: widget.store),
                                ),
                              );
                            },
                          ),
                          ActionButton(
                            icon: Icons.settings_outlined,
                            label: "Custom",
                            onTap: () async {
                              activateStoreCustomization(widget.store.id);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CustomPage(store: widget.store),
                                ),
                              );
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  ResponsiveContent(
                    maxWidth: AppBreakpoints.contentMaxWidth,
                    child: ProductSectionWidget(
                      products: _storeProducts,
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
                ],
              ),
            ),
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
}
