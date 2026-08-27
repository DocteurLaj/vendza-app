import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/models/product_model.dart';

class CathegoryProductPreview extends StatelessWidget {
  const CathegoryProductPreview({super.key, required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final ProductModel? firstProduct = products.isEmpty ? null : products.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        color: AppColors.accent(context).withValues(alpha: 0.10),
        child: firstProduct == null || firstProduct.imageurl.isEmpty
            ? const _DefaultCathegoryIcon()
            : Image.asset(
                firstProduct.imageurl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _DefaultCathegoryIcon(),
              ),
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
