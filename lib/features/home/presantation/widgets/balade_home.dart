import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/home/data/models/home_feed_model.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';
import 'package:vendza/shared/widgets/product/product_price_text.dart';

/// Editorial discovery surface backed exclusively by the live feed/catalog.
class BaladeHome extends StatelessWidget {
  const BaladeHome({
    super.key,
    required this.feed,
    required this.catalogProducts,
    required this.catalogStores,
    required this.onProductTap,
    required this.onStoreTap,
    required this.onAllProducts,
    required this.onAllStores,
    required this.onRefresh,
    this.loading = false,
    this.error,
  });

  final HomeFeedModel feed;
  final List<ProductModel> catalogProducts;
  final List<StoreModel> catalogStores;
  final ValueChanged<ProductModel> onProductTap;
  final ValueChanged<StoreModel> onStoreTap;
  final VoidCallback onAllProducts;
  final VoidCallback onAllStores;
  final Future<void> Function() onRefresh;
  final bool loading;
  final String? error;

  static const _ink = Color(0xFF0B3A40);
  static const _green = Color(0xFF207A4C);
  static const _orange = Color(0xFFB84F21);
  static const _cream = Color(0xFFFAF8F3);

  @override
  Widget build(BuildContext context) {
    final picks = feed.rankedProducts(catalogProducts);
    final storeSeen = <String>{};
    final boutiques = [
      ...feed.featuredStores,
      ...catalogStores,
    ].where((s) => s.id.isNotEmpty && storeSeen.add(s.id)).toList();
    final heroProduct = picks.isEmpty ? null : picks.first;
    final heroStore = boutiques.isEmpty ? null : boutiques.first;
    final secondaryStore = boutiques.length > 1 ? boutiques[1] : null;
    final discoveries = picks.skip(heroProduct == null ? 0 : 1).toList();
    final dark = AppColors.isDark(context);
    final foreground = dark ? AppColors.textPrimary(context) : _ink;
    final canvas = dark ? AppColors.appBackground(context) : _cream;

    return ColoredBox(
      color: canvas,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columnWidth = (width - 56).clamp(0.0, 620.0);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: SizedBox(
                    width: columnWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 23, bottom: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPLORER LA PLACE DU MARCHÉ',
                            style: TextStyle(
                              color: dark
                                  ? AppColors.darkPrimaryAccent
                                  : _orange,
                              fontSize: 11,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chaque boutique a\nquelque chose à offrir.',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 24,
                              height: 1.17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Une sélection sans se presser.',
                            style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (heroProduct != null || heroStore != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (heroProduct != null)
                                  Expanded(
                                    child: _productCard(
                                      context,
                                      heroProduct,
                                      hero: true,
                                    ),
                                  ),
                                if (heroProduct != null && heroStore != null)
                                  const SizedBox(width: 10),
                                if (heroStore != null)
                                  Expanded(
                                    child: _storeHero(context, heroStore),
                                  ),
                              ],
                            ),
                          if (secondaryStore != null) ...[
                            const SizedBox(height: 20),
                            _sectionHeader(
                              context,
                              'La boutique à découvrir',
                              'Voir toutes',
                              onAllStores,
                            ),
                            const SizedBox(height: 10),
                            _featuredStore(context, secondaryStore),
                          ],
                          if (picks.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            _sectionHeader(
                              context,
                              feed.personalized ? 'Pour vous' : 'À découvrir',
                              'Voir tout',
                              onAllProducts,
                            ),
                            const SizedBox(height: 10),
                            if (discoveries.isEmpty)
                              _productCard(context, picks.first)
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: discoveries.length < 12
                                    ? discoveries.length
                                    : 12,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent: 235,
                                    ),
                                itemBuilder: (context, index) =>
                                    _productCard(context, discoveries[index]),
                              ),
                          ],
                          if (heroProduct == null && heroStore == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loading
                                        ? 'Chargement des découvertes…'
                                        : error != null
                                        ? 'Les découvertes sont indisponibles.'
                                        : 'Les découvertes arrivent bientôt.',
                                    style: TextStyle(color: foreground),
                                  ),
                                  if (!loading && error != null)
                                    TextButton(
                                      onPressed: onRefresh,
                                      child: const Text('Réessayer'),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    String action,
    VoidCallback onTap,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            '$action →',
            style: TextStyle(
              color: AppColors.isDark(context)
                  ? AppColors.darkPrimaryAccent
                  : _green,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _productCard(
    BuildContext context,
    ProductModel product, {
    bool hero = false,
  }) {
    return Semantics(
      button: true,
      label: 'Voir l’article ${product.name}',
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onProductTap(product),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(
                  height: hero ? 186 : 146,
                  width: double.infinity,
                  child: SmartImage(path: product.imageurl, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    if (product.storeName.isNotEmpty)
                      Text(
                        product.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ProductPriceText(
                      product.price,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.isDark(context)
                            ? AppColors.darkPrimaryAccent
                            : _green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeHero(BuildContext context, StoreModel store) {
    return Semantics(
      button: true,
      label: 'Visiter la boutique ${store.name}',
      child: Material(
        color: AppColors.isDark(context)
            ? AppColors.darkSurfaceElevated
            : const Color(0xFFE8F0E6),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => onStoreTap(store),
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 264,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (store.image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 80,
                        width: double.infinity,
                        child: SmartImage(path: store.image),
                      ),
                    )
                  else
                    const Icon(
                      Icons.storefront_outlined,
                      size: 40,
                      color: _orange,
                    ),
                  const Spacer(),
                  Text(
                    'À LA RENCONTRE',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.isDark(context)
                          ? AppColors.darkPrimaryAccent
                          : _orange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    store.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Découvrez sa vitrine et ses articles.',
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Visiter la boutique →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.isDark(context)
                          ? AppColors.darkPrimaryAccent
                          : _green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featuredStore(BuildContext context, StoreModel store) {
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => onStoreTap(store),
        borderRadius: BorderRadius.circular(18),
        child: Semantics(
          button: true,
          label: 'Entrer dans la boutique ${store.name}',
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: store.image.isNotEmpty
                        ? SmartImage(path: store.image)
                        : ColoredBox(
                            color: const Color(0xFFE8F0E6),
                            child: Center(
                              child: Text(
                                store.name.isEmpty
                                    ? 'V'
                                    : store.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Explorez sa sélection et ses articles.',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Entrer dans la boutique →',
                        style: TextStyle(
                          color: Color(0xFFFFD7AD),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
