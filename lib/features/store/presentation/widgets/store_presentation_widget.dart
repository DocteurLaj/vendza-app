import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/store/data/models/store_customization_model.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart';
import 'package:vendza/features/store/data/services/product_management_service.dart';
import 'package:vendza/features/product/presentation/pages/product_detail_page.dart';
import 'package:vendza/features/store/presentation/pages/store_product_page.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/social_item.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';
import 'package:vendza/shared/widgets/product/product_price_text.dart';
import 'package:vendza/shared/widgets/social/social_media_links.dart';

class StorePresentationWidget extends StatelessWidget {
  const StorePresentationWidget({super.key, required this.store});

  final StoreModel store;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StoreCustomizationModel>(
      valueListenable: storeCustomization,
      builder: (context, _, _) {
        final storeCustomizationData = customizationForStore(store.id);
        final shouldUseCustomization =
            storeCustomizationData.name.isNotEmpty ||
            isOwnedStoreId(store.id);
        final displayName =
            shouldUseCustomization && storeCustomizationData.name.isNotEmpty
            ? storeCustomizationData.name
            : store.name;
        final displayDescription =
            !shouldUseCustomization ||
                storeCustomizationData.description.isEmpty
            ? store.getDescription()
            : storeCustomizationData.description;
        final coverImage =
            !shouldUseCustomization ||
                storeCustomizationData.coverImageUrl.isEmpty
            ? store.image
            : storeCustomizationData.coverImageUrl;
        final profileImage =
            !shouldUseCustomization ||
                storeCustomizationData.profileImageUrl.isEmpty
            ? coverImage
            : storeCustomizationData.profileImageUrl;
        final List<ProductModel> storeProducts = activeProductsForDetailStore(
          store,
        );
        final List<ProductModel> featuredProducts =
            shouldUseCustomization &&
                storeCustomizationData.featuredProducts.isNotEmpty
            ? activeProducts(storeCustomizationData.featuredProducts)
            : storeProducts.take(4).toList();
        final List<SocialItem> configuredSocials = configuredStoreSocials(
          store.id,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StoreCoverHeader(
              coverImageUrl: coverImage,
              profileImageUrl: profileImage,
            ),
            const SizedBox(height: 58),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.pageTitle(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (configuredSocials.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SocialMediaLinks(socials: configuredSocials),
                  ],
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoreProductPage(
                                store: StoreModel(
                                  id: store.id,
                                  name: displayName,
                                  image: coverImage,
                                  description: displayDescription,
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text(
                          "Voir les produits",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.softSurface(context),
                          foregroundColor: AppColors.accent(context),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StoreProductPreviewTitle(productCount: storeProducts.length),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            StoreFeaturedProductsPreview(products: featuredProducts),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class StoreCoverHeader extends StatelessWidget {
  const StoreCoverHeader({
    super.key,
    required this.coverImageUrl,
    required this.profileImageUrl,
  });

  final String coverImageUrl;
  final String profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final String coverPath = coverImageUrl.trim();
    final String profilePath = profileImageUrl.trim();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          width: double.infinity,
          height: 214,
          child: coverPath.isEmpty
              ? const _StoreHeaderPlaceholder(iconSize: 64)
              : SmartImage(
                  path: coverPath,
                  fit: BoxFit.cover,
                  errorWidget: const _StoreHeaderPlaceholder(iconSize: 64),
                ),
        ),
        Positioned(
          bottom: -48,
          child: Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: profilePath.isEmpty
                  ? const _StoreHeaderPlaceholder(iconSize: 38)
                  : SmartImage(
                      path: profilePath,
                      fit: BoxFit.cover,
                      errorWidget: const _StoreHeaderPlaceholder(iconSize: 38),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreHeaderPlaceholder extends StatelessWidget {
  const _StoreHeaderPlaceholder({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSurface(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        color: AppColors.iconAccent(context),
        size: iconSize,
      ),
    );
  }
}

class StoreProductPreviewTitle extends StatelessWidget {
  const StoreProductPreviewTitle({super.key, required this.productCount});

  final int productCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Produits disponibles",
            style: AppTextStyles.sectionTitle(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.softSurface(context),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            "$productCount produits",
            style: AppTextStyles.label(context),
          ),
        ),
      ],
    );
  }
}

class StoreFeaturedProductsPreview extends StatelessWidget {
  const StoreFeaturedProductsPreview({super.key, required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: EmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          title: "Aucun produit mis en avant",
          message: "Choisis les produits a afficher depuis Custom.",
          compact: true,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useGrid = width >= AppBreakpoints.authCompact;

        if (!useGrid) {
          return SizedBox(
            height: 142,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return StoreFeaturedProductCard(product: products[index]);
              },
            ),
          );
        }

        const spacing = 12.0;
        const minCardWidth = 140.0;
        final crossAxisCount = ((width + spacing) / (minCardWidth + spacing))
            .floor()
            .clamp(2, 4);

        return GridView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: 142,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return StoreFeaturedProductCard(
              product: products[index],
              expandWidth: true,
            );
          },
        );
      },
    );
  }
}

class StoreFeaturedProductCard extends StatelessWidget {
  const StoreFeaturedProductCard({
    super.key,
    required this.product,
    this.expandWidth = false,
  });

  final ProductModel product;
  final bool expandWidth;

  @override
  Widget build(BuildContext context) {
    final String imagePath = product.imageurl.trim();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        width: expandWidth ? double.infinity : 118,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: AppColors.isDark(context) ? 0.12 : 0.045,
              ),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                height: 74,
                child: imagePath.isEmpty
                    ? const _StoreFeaturedProductPlaceholder()
                    : SmartImage(
                        path: imagePath,
                        fit: BoxFit.cover,
                        errorWidget: const _StoreFeaturedProductPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle(
                context,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            ProductPriceText(
              product.price,
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.success(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreFeaturedProductPlaceholder extends StatelessWidget {
  const _StoreFeaturedProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSurface(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.iconAccent(context),
        size: 24,
      ),
    );
  }
}
