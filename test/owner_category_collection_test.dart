import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/domain/owner_store_grouping.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';

ProductModel product({
  required String id,
  required String storeId,
  String categoryId = '',
  String category = '',
  bool active = true,
}) {
  return ProductModel(
    id: id,
    name: 'Product $id',
    price: '10',
    imageurl: '',
    status: 'active',
    storeId: storeId,
    category: category,
    catalogCategoryId: categoryId,
    isActive: active,
  );
}

void main() {
  final store = ListStoreModel(
    id: '1',
    name: 'Boutique',
    description: '',
    imageUrl: '',
    rating: 0,
  );

  test(
    'owner categories show only admin categories used by store products',
    () {
      final categories = [
        SectionModel(id: '10', name: 'Electronique', imageUrl: ''),
        SectionModel(id: '20', name: 'Mode', imageUrl: ''),
        SectionModel(id: '30', name: 'Maison', imageUrl: ''),
      ];
      final products = [
        product(id: 'p1', storeId: '1', categoryId: '10'),
        product(id: 'p2', storeId: '1', categoryId: '10'),
        product(id: 'p3', storeId: '2', categoryId: '20'),
        product(id: 'p4', storeId: '1'),
      ];

      final groups = ownerCategoryGroups(
        store: store,
        products: products,
        globalCategories: categories,
      );

      expect(groups.map((group) => group.category.name), ['Electronique']);
      expect(groups.single.products.map((product) => product.id), ['p1', 'p2']);
    },
  );

  test(
    'owner category grouping falls back to product category name when id is absent',
    () {
      final categories = [
        SectionModel(id: '10', name: 'Electronique', imageUrl: ''),
      ];
      final groups = ownerCategoryGroups(
        store: store,
        products: [product(id: 'p1', storeId: '1', category: 'Electronique')],
        globalCategories: categories,
      );

      expect(groups.single.category.id, '10');
      expect(groups.single.products.single.id, 'p1');
    },
  );

  test('owner categories ignore inactive products', () {
    final categories = [
      SectionModel(id: '10', name: 'Electronique', imageUrl: ''),
    ];
    final groups = ownerCategoryGroups(
      store: store,
      products: [
        product(id: 'p1', storeId: '1', categoryId: '10', active: false),
      ],
      globalCategories: categories,
    );

    expect(groups, isEmpty);
  });

  test(
    'collection assignable products are scoped to the current store and online ids',
    () {
      final products = [
        product(id: '1', storeId: '1'),
        product(id: 'local-2', storeId: '1'),
        product(id: '3', storeId: '2'),
      ];

      final scoped = ownerCollectionAssignableProducts(
        store: store,
        products: products,
      );

      expect(scoped.map((product) => product.id), ['1']);
    },
  );
}
