import 'package:flutter/material.dart';
import 'package:vendza/features/cathegory/data/services/data_exemple.dart';
import 'package:vendza/features/cathegory/presentation/pages/cathegory_produit_page.dart';
import 'package:vendza/features/cathegory/presentation/widgets/cathegory_product_preview.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_data;
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/domain/owner_store_grouping.dart';
import 'package:vendza/shared/widgets/bouton/list_button_section.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';

class CathegoryPage extends StatefulWidget {
  const CathegoryPage({super.key, this.canManage = false, this.store});

  final bool canManage;
  final ListStoreModel? store;

  @override
  State<CathegoryPage> createState() => _CathegoryPageState();
}

class _CathegoryPageState extends State<CathegoryPage> {
  final Set<String> _selectedIds = {};

  List<OwnerCategoryGroup> get _ownerGroups {
    final store = widget.store;
    if (store == null) return const [];
    return ownerCategoryGroups(
      store: store,
      products: store_data.products,
      globalCategories: categories,
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _ownerGroups;
    final visibleCategories = widget.store == null
        ? categories
        : groups.map((group) => group.category).toList();

    return Scaffold(
      appBar: const VendzaPageHeader.back(
        title: 'Catégories utilisées',
        subtitle: 'Navigation par familles de produits',
        icon: Icons.category_outlined,
      ),
      body: ListButtonSection(
        icon: Icons.category_outlined,
        items: visibleCategories,
        emptyTitle: "Aucune catégorie",
        emptyMessage:
            "Les catégories apparaîtront ici quand les produits de cette boutique utiliseront les catégories créées par l'administration.",
        selectedIds: _selectedIds,
        leadingBuilder: (category) => CathegoryProductPreview(
          products: widget.store == null
              ? store_data.products
                    .where(
                      (product) => product.catalogCategoryId == category.id,
                    )
                    .toList()
              : groups
                    .firstWhere((group) => group.category.id == category.id)
                    .products,
        ),
        onPressed: (category) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CathegoryProduitPage(
                category,
                store: widget.store,
                canManage: widget.canManage,
              ),
            ),
          );
          if (mounted) setState(() {});
        },
      ),
    );
  }
}
