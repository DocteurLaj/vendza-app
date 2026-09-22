import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/sizes.dart';
import 'package:vendza/features/store/presentation/widgets/product_store_widget.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';
import 'package:vendza/shared/widgets/product/product_price_text.dart';
import 'package:vendza/shared/widgets/product/product_view_mode.dart';

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
    this.showViewToggle = true,
  });

  final List<ProductModel> products;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(ProductModel product)? onProductTap;
  final void Function(ProductModel product)? onProductLongPress;
  final bool ownerMode;
  final bool showInactiveProducts;
  final bool showViewToggle;

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

    return ValueListenableBuilder<ProductViewMode>(
      valueListenable: productViewModeStore,
      builder: (context, mode, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showViewToggle)
              _ProductViewModeBar(
                mode: mode,
                onChanged: (value) => productViewModeStore.value = value,
              ),
            if (mode == ProductViewMode.list)
              _ProductListView(
                products: visibleProducts,
                ownerMode: ownerMode,
                selectionMode: selectionMode,
                selectedIds: selectedIds,
                onProductTap: onProductTap,
                onProductLongPress: onProductLongPress,
              )
            else
              _ProductGridView(
                products: visibleProducts,
                ownerMode: ownerMode,
                selectionMode: selectionMode,
                selectedIds: selectedIds,
                onProductTap: onProductTap,
                onProductLongPress: onProductLongPress,
              ),
          ],
        );
      },
    );
  }
}

class _ProductViewModeBar extends StatelessWidget {
  const _ProductViewModeBar({required this.mode, required this.onChanged});

  final ProductViewMode mode;
  final ValueChanged<ProductViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.contentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ProductViewMode.values.map((value) {
                  final selected = value == mode;
                  return Tooltip(
                    message: 'Vue ${value.label.toLowerCase()}',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => onChanged(value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent(context)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              value.icon,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary(context),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 5),
                              Text(
                                value.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductGridView extends StatelessWidget {
  const _ProductGridView({
    required this.products,
    required this.ownerMode,
    required this.selectionMode,
    required this.selectedIds,
    this.onProductTap,
    this.onProductLongPress,
  });

  final List<ProductModel> products;
  final bool ownerMode;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(ProductModel product)? onProductTap;
  final void Function(ProductModel product)? onProductLongPress;

  @override
  Widget build(BuildContext context) {
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
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
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

class _ProductListView extends StatelessWidget {
  const _ProductListView({
    required this.products,
    required this.ownerMode,
    required this.selectionMode,
    required this.selectedIds,
    this.onProductTap,
    this.onProductLongPress,
  });

  final List<ProductModel> products;
  final bool ownerMode;
  final bool selectionMode;
  final Set<String> selectedIds;
  final void Function(ProductModel product)? onProductTap;
  final void Function(ProductModel product)? onProductLongPress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.contentMaxWidth,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductListTile(
              product: product,
              ownerMode: ownerMode,
              selectionMode: selectionMode,
              isSelected: selectedIds.contains(product.id),
              onTap: onProductTap == null ? null : () => onProductTap!(product),
              onLongPress: onProductLongPress == null
                  ? null
                  : () => onProductLongPress!(product),
            );
          },
        ),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.product,
    required this.ownerMode,
    required this.selectionMode,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  final ProductModel product;
  final bool ownerMode;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final productImagePath = product.imageurl.trim();
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: ownerMode || product.isActive ? 1 : 0.58,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent(context)
                  : AppColors.border(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: productImagePath.isEmpty
                      ? _ProductListImageFallback()
                      : SmartImage(
                          path: productImagePath,
                          fit: BoxFit.cover,
                          errorWidget: _ProductListImageFallback(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (selectionMode)
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? AppColors.accent(context)
                                : AppColors.textSecondary(context),
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ProductPriceText(
                      product.price,
                      style: TextStyle(
                        color: AppColors.success(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ProductStockBadge(product: product, compact: true),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductListImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSurface(context),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary(context),
      ),
    );
  }
}
