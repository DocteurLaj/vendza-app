import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class StackedActionPreview extends StatelessWidget {
  const StackedActionPreview({
    super.key,
    required this.products,
    required this.fallbackIcon,
  });

  final List<ProductModel> products;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final previewProducts = products.take(3).toList();

    return SizedBox(
      width: 42,
      height: 34,
      child: previewProducts.isEmpty
          ? Icon(fallbackIcon, color: AppColors.iconAccent(context), size: 25)
          : Stack(
              clipBehavior: Clip.none,
              children: [
                for (
                  int index = previewProducts.length - 1;
                  index >= 0;
                  index--
                )
                  Positioned(
                    left: index * 6,
                    top: index * 3,
                    child: _PreviewSheet(
                      imageUrl: previewProducts[index].imageurl,
                      fallbackIcon: fallbackIcon,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.imageUrl, required this.fallbackIcon});

  final String imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final cardColor = AppColors.card(context);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: cardColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.16 : 0.08,
            ),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.5),
        child: imageUrl.isEmpty
            ? _PreviewFallback(icon: fallbackIcon)
            : SmartImage(
                path: imageUrl,
                fit: BoxFit.cover,
                errorWidget: _PreviewFallback(icon: fallbackIcon),
              ),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent(context).withValues(alpha: 0.08),
      child: Icon(icon, color: AppColors.iconAccent(context), size: 17),
    );
  }
}
