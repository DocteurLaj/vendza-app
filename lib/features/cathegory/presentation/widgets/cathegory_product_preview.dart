import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class CathegoryProductPreview extends StatelessWidget {
  const CathegoryProductPreview({super.key, required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final previewProducts = products.take(3).toList();

    return SizedBox(
      width: 58,
      height: 46,
      child: previewProducts.isEmpty
          ? const _DefaultCathegoryTile()
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
                    child: _StackedCathegoryImage(
                      imageUrl: previewProducts[index].imageurl,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StackedCathegoryImage extends StatelessWidget {
  const _StackedCathegoryImage({required this.imageUrl});

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
            ? const _DefaultCathegoryIcon()
            : SmartImage(
                path: imageUrl,
                fit: BoxFit.cover,
                errorWidget: const _DefaultCathegoryIcon(),
              ),
      ),
    );
  }
}

class _DefaultCathegoryTile extends StatelessWidget {
  const _DefaultCathegoryTile();

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
        child: const _DefaultCathegoryIcon(),
      ),
    );
  }
}

class _DefaultCathegoryIcon extends StatelessWidget {
  const _DefaultCathegoryIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.category_outlined,
      color: AppColors.iconAccent(context),
      size: 24,
    );
  }
}
