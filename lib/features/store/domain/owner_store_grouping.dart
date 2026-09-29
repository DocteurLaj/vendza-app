import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';

class OwnerCategoryGroup {
  const OwnerCategoryGroup({required this.category, required this.products});

  final SectionModel category;
  final List<ProductModel> products;
}

bool productBelongsToOwnerStore(ProductModel product, ListStoreModel store) {
  return product.storeId == store.id ||
      (store.localId.isNotEmpty && product.storeId == store.localId);
}

List<OwnerCategoryGroup> ownerCategoryGroups({
  required ListStoreModel store,
  required List<ProductModel> products,
  required List<SectionModel> globalCategories,
}) {
  final categoriesById = {
    for (final category in globalCategories) category.id: category,
  };
  final categoriesByName = {
    for (final category in globalCategories)
      category.name.trim().toLowerCase(): category,
  };
  final grouped = <String, List<ProductModel>>{};

  for (final product in products.where(
    (product) => productBelongsToOwnerStore(product, store),
  )) {
    final category =
        categoriesById[product.catalogCategoryId] ??
        categoriesByName[product.category.trim().toLowerCase()];
    if (category == null) continue;
    grouped.putIfAbsent(category.id, () => <ProductModel>[]).add(product);
  }

  return globalCategories
      .where((category) => grouped.containsKey(category.id))
      .map(
        (category) => OwnerCategoryGroup(
          category: category,
          products: List<ProductModel>.unmodifiable(grouped[category.id]!),
        ),
      )
      .toList(growable: false);
}

List<ProductModel> productsForOwnerCategory({
  required ListStoreModel store,
  required SectionModel category,
  required List<ProductModel> products,
}) {
  final lowerName = category.name.trim().toLowerCase();
  return products
      .where((product) => productBelongsToOwnerStore(product, store))
      .where(
        (product) =>
            product.catalogCategoryId == category.id ||
            (product.catalogCategoryId.isEmpty &&
                product.category.trim().toLowerCase() == lowerName),
      )
      .toList(growable: false);
}

List<ProductModel> ownerCollectionAssignableProducts({
  required ListStoreModel store,
  required List<ProductModel> products,
}) {
  return products
      .where((product) => productBelongsToOwnerStore(product, store))
      .where((product) => int.tryParse(product.id) != null)
      .where((product) => product.isActive && !product.syncStatus.isPending)
      .toList(growable: false);
}
