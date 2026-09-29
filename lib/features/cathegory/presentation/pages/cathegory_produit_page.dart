import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_data;
import 'package:vendza/features/store/domain/owner_store_grouping.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';

class CathegoryProduitPage extends StatefulWidget {
  const CathegoryProduitPage(
    this.cathegory, {
    super.key,
    this.store,
    this.canManage = false,
  });

  final SectionModel cathegory;
  final ListStoreModel? store;
  final bool canManage;

  @override
  State<CathegoryProduitPage> createState() => _CathegoryProduitPageState();
}

class _CathegoryProduitPageState extends State<CathegoryProduitPage> {
  List<ProductModel> get categoryProducts {
    final store = widget.store;
    if (store == null) {
      return store_data.products
          .where((product) => product.catalogCategoryId == widget.cathegory.id)
          .toList();
    }
    return productsForOwnerCategory(
      store: store,
      category: widget.cathegory,
      products: store_data.products,
    );
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
    );
  }
}
