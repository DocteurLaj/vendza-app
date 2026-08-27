import 'package:flutter/material.dart';
import 'package:vendza/core/constants/app_interaction_tokens.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/home/data/models/store_model.dart' as detail;
import 'package:vendza/features/store/data/models/store_customization_model.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_data;
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/social_item.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';
import 'package:vendza/shared/widgets/product/product_price_text.dart';
import 'package:vendza/shared/widgets/social/social_media_links.dart';

class ProductDetailHero extends StatelessWidget {
  const ProductDetailHero({
    super.key,
    required this.imageUrl,
    this.showFullImage = false,
    this.compactHeight,
  });

  final String imageUrl;
  final bool showFullImage;
  final double? compactHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double imageHeight = showFullImage
            ? constraints.maxHeight
            : (compactHeight ?? 320).clamp(260.0, constraints.maxHeight);
        final double dotBottom = showFullImage
            ? 104
            : (constraints.maxHeight - imageHeight + 18).clamp(18.0, 104.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              color: showFullImage
                  ? Colors.black
                  : AppColors.softSurface(context),
              alignment: Alignment.topCenter,
              child: ProductDetailAssetImage(
                path: imageUrl,
                height: imageHeight,
                borderRadius: 0,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: dotBottom,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProductDetailHeroDot(isActive: true),
                  SizedBox(width: 6),
                  ProductDetailHeroDot(isActive: false),
                  SizedBox(width: 6),
                  ProductDetailHeroDot(isActive: false),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProductDetailBackButton extends StatelessWidget {
  const ProductDetailBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.card(context).withValues(alpha: 0.88),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.iconAccent(context),
          size: 19,
        ),
      ),
    );
  }
}

class ProductDetailFloatingActions extends StatelessWidget {
  const ProductDetailFloatingActions({
    super.key,
    required this.expanded,
    required this.isLiked,
    required this.onToggle,
    required this.onLike,
    required this.onShare,
  });

  final bool expanded;
  final bool isLiked;
  final VoidCallback onToggle;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 18,
      bottom: bottomPadding + 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingActionOption(
            visible: expanded,
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.redAccent : AppColors.iconAccent(context),
            onPressed: onLike,
          ),
          const SizedBox(height: 10),
          _FloatingActionOption(
            visible: expanded,
            icon: Icons.share_outlined,
            color: AppColors.iconAccent(context),
            onPressed: onShare,
          ),
          const SizedBox(height: 12),
          AppInteractive(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: expanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingActionOption extends StatelessWidget {
  const _FloatingActionOption({
    required this.visible,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final bool visible;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 140),
        child: IgnorePointer(
          ignoring: !visible,
          child: AppInteractive(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(23),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductDetailContentPanel extends StatelessWidget {
  const ProductDetailContentPanel({
    super.key,
    required this.product,
    required this.displayedPrice,
    required this.selectedVariantIndex,
    required this.socialItems,
    required this.isExpanded,
    this.minHeight,
    required this.onVariantSelected,
    required this.onContactSeller,
  });

  final ProductModel product;
  final String displayedPrice;
  final int? selectedVariantIndex;
  final List<SocialItem> socialItems;
  final bool isExpanded;
  final double? minHeight;
  final ValueChanged<int> onVariantSelected;
  final VoidCallback onContactSeller;

  @override
  Widget build(BuildContext context) {
    final bool hasVariants = product.variants.isNotEmpty;
    final bool hasSocials = socialItems.isNotEmpty;
    final double socialDockHeight = hasSocials ? 124 : 0;
    final Widget expandedContent = Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, hasSocials ? 18 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.accent(context).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          ProductDetailHeader(
            product: product,
            name: product.name,
            price: displayedPrice,
            description: product.description.isNotEmpty
                ? product.description
                : "Montre connectee legere et elegante avec suivi de sante, notifications et autonomie longue duree. Parfaite pour le quotidien et le sport.",
          ),
          if (hasVariants) ...[
            const SizedBox(height: 18),
            Text(
              "Choisir une variante",
              style: TextStyle(
                color: AppColors.sectionTitle(context),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ProductVariantChips(
              variants: product.variants,
              selectedIndex: selectedVariantIndex,
              onSelected: onVariantSelected,
            ),
          ],
          SizedBox(height: hasVariants ? 14 : 18),
          ProductDetailActionButtons(onContactSeller: onContactSeller),
        ],
      ),
    );
    final Widget collapsedContent = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: ProductPriceText(
                  displayedPrice,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.success(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppColors.textSecondary(context),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                "Afficher les details",
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.fastOutSlowIn,
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isExpanded ? 0 : 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isExpanded ? 30 : 26),
          topRight: Radius.circular(isExpanded ? 30 : 26),
          bottomLeft: Radius.circular(isExpanded ? 0 : 26),
          bottomRight: Radius.circular(isExpanded ? 0 : 26),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(24, 0, 0, 0),
            blurRadius: 26,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: isExpanded
          ? Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: hasSocials ? 12 : 0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: ((minHeight ?? 0) - socialDockHeight)
                            .clamp(0, double.infinity)
                            .toDouble(),
                      ),
                      // Do not wrap in IntrinsicHeight: ProductPriceText uses
                      // LayoutBuilder, which cannot compute intrinsic sizes.
                      child: expandedContent,
                    ),
                  ),
                ),
                if (hasSocials)
                  ProductDetailSocialDock(socialItems: socialItems),
              ],
            )
          : collapsedContent,
    );
  }
}

class ProductDetailSocialDock extends StatelessWidget {
  const ProductDetailSocialDock({super.key, required this.socialItems});

  final List<SocialItem> socialItems;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(10, 0, 0, 0),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SocialMediaLinks(
          socials: socialItems,
          title: "Retrouvez la boutique",
        ),
      ),
    );
  }
}

class ProductDetailHeader extends StatelessWidget {
  const ProductDetailHeader({
    super.key,
    required this.product,
    required this.name,
    required this.price,
    required this.description,
  });

  final ProductModel product;
  final String name;
  final String price;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary(context),
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ProductOwnerStoreLink(product: product),
          ],
        ),
        const SizedBox(height: 6),
        ProductPriceText(
          price,
          style: TextStyle(
            color: AppColors.success(context),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class ProductVariantChips extends StatelessWidget {
  const ProductVariantChips({
    super.key,
    required this.variants,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ProductVariantModel> variants;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(variants.length, (index) {
          final ProductVariantModel variant = variants[index];
          final bool isSelected = selectedIndex == index;

          return Padding(
            padding: EdgeInsets.only(
              right: index == variants.length - 1 ? 0 : 10,
            ),
            child: AppInteractive(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: AppInteractionTokens.duration,
                curve: AppInteractionTokens.curve,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent(context)
                      : AppColors.card(context),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent(context)
                        : AppColors.border(context),
                  ),
                ),
                child: Text(
                  variant.name.isNotEmpty
                      ? variant.name
                      : "Variante ${index + 1}",
                  style: TextStyle(
                    color: isSelected
                        ? (AppColors.isDark(context)
                              ? AppColors.darkBackground
                              : Colors.white)
                        : AppColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ProductDetailActionButtons extends StatelessWidget {
  const ProductDetailActionButtons({super.key, required this.onContactSeller});

  final VoidCallback onContactSeller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: const Text(
              "Acheter maintenant",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent(context),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.muted(
                context,
              ).withValues(alpha: AppColors.isDark(context) ? 0.28 : 0.42),
              disabledForegroundColor: AppColors.isDark(context)
                  ? AppColors.darkTextSecondary
                  : Colors.white.withValues(alpha: 0.92),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: onContactSeller,
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text(
              "Contacter le vendeur",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent(context),
              side: BorderSide(color: AppColors.accent(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProductOwnerStoreLink extends StatefulWidget {
  const ProductOwnerStoreLink({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductOwnerStoreLink> createState() => _ProductOwnerStoreLinkState();
}

class _ProductOwnerStoreLinkState extends State<ProductOwnerStoreLink> {
  bool _showStoreName = false;

  void _handleTap(StoreCustomizationModel customization) {
    final detail.StoreModel store = _buildStore(customization);

    if (!_showStoreName) {
      setState(() => _showStoreName = true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoreDetailPage(store: store)),
    );
  }

  detail.StoreModel _buildStore(StoreCustomizationModel customization) {
    if (widget.product.storeId.trim().isNotEmpty) {
      for (final store in store_data.stores) {
        if (store.id != widget.product.storeId) continue;

        return detail.StoreModel(
          id: store.id,
          name: store.name,
          image: store.imageUrl,
          description: store.description,
        );
      }
    }

    return detail.StoreModel(
      id: store_data.stores.isEmpty ? "" : store_data.stores.first.id,
      name: widget.product.storeName.trim().isNotEmpty
          ? widget.product.storeName.trim()
          : customization.name,
      image: customization.profileImageUrl.isEmpty
          ? customization.coverImageUrl
          : customization.profileImageUrl,
      description: customization.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StoreCustomizationModel>(
      valueListenable: store_data.storeCustomization,
      builder: (context, customization, _) {
        final detail.StoreModel store = _buildStore(customization);
        final String displayStoreName = store.name.trim().isEmpty
            ? "Boutique"
            : store.name.trim();
        final String storeImage = store.image;

        return TapRegion(
          onTapOutside: (_) {
            if (_showStoreName) {
              setState(() => _showStoreName = false);
            }
          },
          child: AppInteractive(
            onTap: () => _handleTap(customization),
            borderRadius: BorderRadius.circular(18),
            enableHoverElevation: true,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(maxWidth: 154),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border(context)),
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
                  ClipOval(
                    child: ProductDetailStoreImage(imageUrl: storeImage),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: _showStoreName
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 7),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 96),
                                child: Text(
                                  displayStoreName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.iconAccent(context),
                                size: 10,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProductDetailStoreImage extends StatelessWidget {
  const ProductDetailStoreImage({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: imageUrl.isEmpty
          ? const ProductDetailStorePlaceholder()
          : Image.asset(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ProductDetailStorePlaceholder(),
            ),
    );
  }
}

class ProductDetailStorePlaceholder extends StatelessWidget {
  const ProductDetailStorePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent(context).withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        color: AppColors.iconAccent(context),
        size: 16,
      ),
    );
  }
}

class ProductDetailHeroDot extends StatelessWidget {
  const ProductDetailHeroDot({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 9 : 7,
      height: isActive ? 9 : 7,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}

class ProductDetailAssetImage extends StatelessWidget {
  const ProductDetailAssetImage({
    super.key,
    required this.path,
    required this.height,
    this.width = double.infinity,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String path;
  final double width;
  final double height;
  final double? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final Widget placeholder = Container(
      color: AppColors.softSurface(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.muted(context),
        size: 42,
      ),
    );
    final String imagePath = path.trim();
    final Widget image = imagePath.isEmpty
        ? placeholder
        : SmartImage(path: imagePath, fit: fit, errorWidget: placeholder);

    final Widget sized = SizedBox(width: width, height: height, child: image);

    if (borderRadius == null || borderRadius == 0) {
      return sized;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius!),
      child: sized,
    );
  }
}
