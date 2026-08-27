import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/models/product_model.dart';

class CollectionProductStackPreview extends StatelessWidget {
  const CollectionProductStackPreview({super.key, required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final previewProducts = products.take(3).toList();

    return SizedBox(
      width: 58,
      height: 46,
      child: previewProducts.isEmpty
          ? const _EmptyCollectionIcon()
          : Stack(
              clipBehavior: Clip.none,
              children: [
                for (
                  int index = previewProducts.length - 1;
                  index >= 0;
                  index--
                )
                  Positioned(
                    left: index * 10,
                    top: index * 3,
                    child: _StackedProductImage(
                      imageUrl: previewProducts[index].imageurl,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StackedProductImage extends StatelessWidget {
  const _StackedProductImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.card(context);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.16 : 0.08,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl.isEmpty
            ? const _PreviewPlaceholder()
            : Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _PreviewPlaceholder(),
              ),
      ),
    );
  }
}

class _EmptyCollectionIcon extends StatelessWidget {
  const _EmptyCollectionIcon();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.accent(context).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.collections_outlined,
          color: AppColors.iconAccent(context),
          size: 24,
        ),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.inventory_2_outlined,
      color: AppColors.iconAccent(context),
      size: 18,
    );
  }
}
