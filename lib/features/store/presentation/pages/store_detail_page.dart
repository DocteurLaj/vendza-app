import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/share/app_share_service.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/home/data/services/data_exemple.dart'
    as home_data;
import 'package:vendza/features/cathegory/data/services/data_exemple.dart'
    as category_data;
import 'package:vendza/features/collection/data/services/data_exemple.dart'
    as collection_data;
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/store/data/services/product_api_service.dart';
import 'package:vendza/features/store/data/services/store_catalog_api_service.dart';
import 'package:vendza/features/store/presentation/widgets/store_presentation_widget.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class StoreDetailPage extends StatefulWidget {
  const StoreDetailPage({super.key, required this.store});

  final StoreModel store;

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  bool _isLoadingProducts = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPublicStoreData();
  }

  Future<void> _loadPublicStoreData() async {
    final storeId = int.tryParse(widget.store.id);
    if (storeId == null) {
      setState(() => _isLoadingProducts = false);
      return;
    }
    setState(() {
      _isLoadingProducts = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        ProductApiService().searchProducts(storeId: storeId, inStock: false),
        StoreCatalogApiService().categories(storeId),
        StoreCatalogApiService().collections(storeId),
      ]);
      final publicProducts = (results[0] as List<Map<String, dynamic>>)
          .map(ProductModel.fromJson)
          .where((product) => product.isActive && !product.adminDisabled)
          .toList();
      home_data.products
        ..removeWhere((product) => product.storeId == widget.store.id)
        ..addAll(publicProducts);
      final categories = results[1] as List<SectionModel>;
      category_data.replaceCategoriesForStore(widget.store.id, categories);
      final collections = results[2] as List<SectionModel>;
      collection_data.replaceCollectionsForStore(widget.store.id, collections);
      final assignments = collection_data.collectionProductsForStore(
        widget.store.id,
      );
      assignments.clear();
      for (final collection in collections) {
        assignments[collection.id] = publicProducts
            .where((product) => collection.productIds.contains(product.id))
            .toList();
      }
    } on Object catch (error) {
      _loadError = error;
    }
    if (mounted) setState(() => _isLoadingProducts = false);
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = isStoreFavorite(widget.store);
    final storeSurface = AppColors.appBackground(context);

    return Scaffold(
      backgroundColor: storeSurface,
      appBar: AppBar(
        backgroundColor: storeSurface,
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Boutique",
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final added = await toggleStoreFavorite(widget.store);
                if (!mounted) return;
                setState(() {});
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      added
                          ? "Boutique ajoutée aux favoris"
                          : "Boutique retirée des favoris",
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } on Object catch (error) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : AppColors.accent(context),
            ),
          ),
          IconButton(
            onPressed: () => AppShareService.shareStore(context, widget.store),
            icon: Icon(Icons.share_outlined, color: AppColors.accent(context)),
          ),
        ],
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Impossible de charger les produits de cette boutique.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadPublicStoreData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: ResponsiveContent(
                maxWidth: AppBreakpoints.contentMaxWidth,
                child: StorePresentationWidget(store: widget.store),
              ),
            ),
    );
  }
}
