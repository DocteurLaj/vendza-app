import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/collection/presentation/widgets/assign_products_dialog.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_data;
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';
import 'package:vendza/shared/widgets/dialog/category_change_warning_dialog.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';

class CathegoryProduitPage extends StatefulWidget {
  const CathegoryProduitPage(
    this.cathegory, {
    super.key,
    this.canManage = false,
  });

  final SectionModel cathegory;
  final bool canManage;

  @override
  State<CathegoryProduitPage> createState() => _CathegoryProduitPageState();
}

class _CathegoryProduitPageState extends State<CathegoryProduitPage> {
  List<ProductModel> get categoryProducts => store_data.products
      .where((product) => product.category == widget.cathegory.name)
      .toList();

  Future<void> _assignProducts() async {
    final selectedProducts = await showAssignProductsDialog(
      context: context,
      products: store_data.products,
      selectedProducts: categoryProducts,
      title: "Assigner des produits",
      subtitle:
          "Choisis les produits à rattacher à ${widget.cathegory.name}. Les produits décochés quitteront cette catégorie.",
    );

    if (selectedProducts == null) return;
    if (!mounted) return;

    final selectedIds = selectedProducts.map((product) => product.id).toSet();
    final movedProducts = selectedProducts
        .where(
          (product) =>
              product.category.isNotEmpty &&
              product.category != widget.cathegory.name,
        )
        .toList();

    if (movedProducts.isNotEmpty) {
      final confirmed = await showCategoryChangeWarningDialog(
        context: context,
        productCount: movedProducts.length,
        categoryName: widget.cathegory.name,
      );

      if (!confirmed) return;
      if (!mounted) return;
    }

    setState(() {
      for (int index = 0; index < store_data.products.length; index++) {
        final product = store_data.products[index];

        if (selectedIds.contains(product.id)) {
          store_data.products[index] = product.copyWith(
            category: widget.cathegory.name,
          );
        } else if (product.category == widget.cathegory.name) {
          store_data.products[index] = product.copyWith(category: "");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = categoryProducts;

    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(title: Text(widget.cathegory.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14, bottom: 88),
        child: ResponsiveContent(
          maxWidth: 920,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Produits de ${widget.cathegory.name}",
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                EmptyStateWidget(
                  icon: Icons.category_outlined,
                  title: "Catégorie vide",
                  message: widget.canManage
                      ? "Ajoute des produits existants à cette catégorie quand tu veux."
                      : "Aucun produit n'est disponible dans cette catégorie.",
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
