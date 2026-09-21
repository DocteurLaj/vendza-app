import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/api_mappers.dart';
import 'package:vendza/features/product/presentation/helpers/product_stock_presentation.dart';
import 'package:vendza/shared/models/product_model.dart';

ProductModel product({required int stock, bool isActive = true}) =>
    ProductModel(
      id: '1',
      name: 'Produit test',
      price: '100',
      imageurl: '',
      status: '',
      stock: stock,
      isActive: isActive,
    );

void main() {
  group('product stock presentation', () {
    test('maps API stock into ProductModel', () {
      final mapped = productFromApi({
        'idproduct': 7,
        'title': 'Produit API',
        'price': '15.00',
        'stock': 4,
        'images': [],
      });

      expect(mapped.stock, 4);
      expect(mapped.isActive, isTrue);
    });

    test('labels available, low, and out of stock products clearly', () {
      expect(productStockLabel(product(stock: 12)), '12 en stock');
      expect(productStockLabel(product(stock: 3)), 'Stock faible · 3');
      expect(productStockLabel(product(stock: 0)), 'Rupture de stock');
    });

    test('uses discreet severity for product cards and details', () {
      expect(productStockTone(product(stock: 12)), ProductStockTone.available);
      expect(productStockTone(product(stock: 3)), ProductStockTone.low);
      expect(productStockTone(product(stock: 0)), ProductStockTone.out);
      expect(productStockIcon(product(stock: 0)).codePoint, isNonZero);
    });
  });
}
