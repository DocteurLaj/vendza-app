import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/product/presentation/pages/product_detail_page.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';
import 'package:vendza/shared/widgets/product/product_price_text.dart';

class ProductStoreWidget extends StatelessWidget {
  const ProductStoreWidget({
    super.key,
    required this.product,
    this.ownerMode = false,
    this.selectionMode = false,
    this.isSelected = false,
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
    final String productImagePath = product.imageurl.trim();
    final isDark = AppColors.isDark(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = (constraints.maxHeight * 0.5)
            .clamp(112.0, 144.0)
            .toDouble();

        return AppInteractive(
          onTap:
              onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(
                      product: product,
                      ownerMode: ownerMode,
                    ),
                  ),
                );
              },
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          enableHoverElevation: true,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: ownerMode || product.isActive ? 1 : 0.58,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: AppColors.accent(context), width: 2)
                    : Border.all(color: AppColors.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: imageHeight,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: productImagePath.isEmpty
                                ? _ProductImageFallback(height: imageHeight)
                                : SmartImage(
                                    path: productImagePath,
                                    fit: BoxFit.cover,
                                    errorWidget: _ProductImageFallback(
                                      height: imageHeight,
                                    ),
                                  ),
                          ),
                          if (ownerMode)
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: _OwnerProductStatusBadge(
                                isActive: product.isActive,
                              ),
                            ),
                          if (selectionMode)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accent(context)
                                      : AppColors.card(
                                          context,
                                        ).withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent(context),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.2,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 7),
                            ProductPriceText(
                              product.price,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.success(context),
                              ),
                            ),
                            if (product.storeName.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.storefront_outlined,
                                    color: AppColors.textSecondary(context),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      product.storeName.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textSecondary(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OwnerProductStatusBadge extends StatelessWidget {
  const _OwnerProductStatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isActive
        ? const Color(0xFFEAF4EE)
        : const Color(0xFFFFECEC);
    final Color foregroundColor = isActive
        ? const Color(0xFF1F7A4B)
        : const Color(0xFFB3261E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: foregroundColor,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? "Actif" : "Inactif",
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      color: AppColors.softSurface(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        color: AppColors.textSecondary(context),
      ),
    );
  }
}
