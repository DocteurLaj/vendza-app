import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/collection/data/services/data_exemple.dart';
import 'package:vendza/features/collection/presentation/widgets/assign_products_dialog.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_data;
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';

class CollectionProduitPage extends StatefulWidget {
  const CollectionProduitPage(
    this.collection, {
    super.key,
    this.canManage = false,
  });

  final SectionModel collection;
  final bool canManage;

  @override
  State<CollectionProduitPage> createState() => _CollectionProduitPageState();
}

class _CollectionProduitPageState extends State<CollectionProduitPage> {
  List<ProductModel> get assignedProducts =>
      collectionProducts[widget.collection.id] ?? <ProductModel>[];

  Future<void> _assignProducts() async {
    final List<ProductModel>? selectedProducts = await showAssignProductsDialog(
      context: context,
      products: store_data.products,
      selectedProducts: assignedProducts,
    );

    if (selectedProducts == null) return;

    try {
      await collectionRepository.assignProducts(
        collectionId: widget.collection.id,
        products: selectedProducts,
      );
      if (mounted) setState(() {});
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ProductModel> products = assignedProducts;

    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(title: Text(widget.collection.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14, bottom: 88),
        child: ResponsiveContent(
          maxWidth: 920,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Produits de ${widget.collection.name}",
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                EmptyStateWidget(
                  icon: Icons.collections_outlined,
                  title: "Collection vide",
                  message: widget.canManage
                      ? "Ajoute des produits existants dans cette collection."
                      : "Aucun produit n'est disponible dans cette collection.",
                )
              else
                ProductSectionWidget(products: products),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: _assignProducts,
              icon: const Icon(Icons.add),
              label: const Text("Produit"),
            )
          : null,
    );
  }
}
