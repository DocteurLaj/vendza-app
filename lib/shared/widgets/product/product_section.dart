import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/sizes.dart';
import 'package:vendza/features/store/presentation/widgets/product_store_widget.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';

class ProductSectionWidget extends StatelessWidget {
  const ProductSectionWidget({
    super.key,
    required this.products,
    this.selectionMode = false,
    this.selectedIds = const <String>{},
    this.onProductTap,
    this.onProductLongPress,
    this.ownerMode = false,
    this.showInactiveProducts = false,
  });

  final List<ProductModel> products;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(ProductModel product)? onProductTap;
  final void Function(ProductModel product)? onProductLongPress;
  final bool ownerMode;
  final bool showInactiveProducts;

  @override
  Widget build(BuildContext context) {
    final visibleProducts = showInactiveProducts
        ? products
        : products.where((product) => product.isActive).toList();

    if (visibleProducts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: "Aucun produit disponible",
        message: "Les produits ajoutés apparaîtront ici.",
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth.clamp(
          0,
          AppBreakpoints.contentMaxWidth,
        );
        final horizontalPadding = AppSizes.padding * 2;
        final availableWidth = (contentWidth - horizontalPadding).clamp(
          0,
          double.infinity,
        );
        const spacing = 12.0;
        const maxTileWidth = 188.0;
        final crossAxisCount =
            ((availableWidth + spacing) / (maxTileWidth + spacing))
                .ceil()
                .clamp(2, 6);
        final tileWidth =
            (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
        final tileHeight = (tileWidth * 1.54).clamp(238.0, 286.0);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: tileHeight,
              ),
              itemCount: visibleProducts.length,
              itemBuilder: (context, index) {
                final product = visibleProducts[index];

                return RepaintBoundary(
                  child: ProductStoreWidget(
                    product: product,
                    ownerMode: ownerMode,
                    selectionMode: selectionMode,
                    isSelected: selectedIds.contains(product.id),
                    onTap: onProductTap == null
                        ? null
                        : () => onProductTap!(product),
                    onLongPress: onProductLongPress == null
                        ? null
                        : () => onProductLongPress!(product),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
