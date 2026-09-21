import 'package:flutter/material.dart';
import 'package:vendza/shared/models/product_model.dart';

enum ProductStockTone { available, low, out }

const int lowStockThreshold = 5;

ProductStockTone productStockTone(ProductModel product) {
  if (product.stock <= 0 || !product.isActive) return ProductStockTone.out;
  if (product.stock <= lowStockThreshold) return ProductStockTone.low;
  return ProductStockTone.available;
}

String productStockLabel(ProductModel product) {
  return switch (productStockTone(product)) {
    ProductStockTone.out => 'Rupture de stock',
    ProductStockTone.low => 'Stock faible · ${product.stock}',
    ProductStockTone.available => '${product.stock} en stock',
  };
}

IconData productStockIcon(ProductModel product) {
  return switch (productStockTone(product)) {
    ProductStockTone.out => Icons.remove_shopping_cart_outlined,
    ProductStockTone.low => Icons.inventory_2_outlined,
    ProductStockTone.available => Icons.check_circle_outline,
  };
}

Color productStockForeground(ProductStockTone tone, BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (tone) {
    ProductStockTone.available =>
      dark ? const Color(0xFF7DD3A8) : const Color(0xFF2E7D55),
    ProductStockTone.low =>
      dark ? const Color(0xFFFFD166) : const Color(0xFFB7791F),
    ProductStockTone.out =>
      dark ? const Color(0xFFFCA5A5) : const Color(0xFFC53030),
  };
}

Color productStockBackground(ProductStockTone tone, BuildContext context) {
  return productStockForeground(tone, context).withValues(alpha: 0.10);
}
