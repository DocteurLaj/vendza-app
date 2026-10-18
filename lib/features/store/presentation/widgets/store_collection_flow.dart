import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/collection/presentation/pages/collection_page.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/models/section_model.dart';
import 'package:vendza/shared/widgets/product/product_section.dart';

int? randomCollectionInsertionIndex(int productCount, Random random) {
  if (productCount < 2) return null;
  return 1 + random.nextInt(productCount - 1);
}

class StoreCollectionFlow extends StatefulWidget {
  const StoreCollectionFlow({
    super.key,
    required this.products,
    required this.collections,
    required this.storeId,
  });

  final List<ProductModel> products;
  final List<SectionModel> collections;
  final String storeId;

  @override
  State<StoreCollectionFlow> createState() => _StoreCollectionFlowState();
}

class _StoreCollectionFlowState extends State<StoreCollectionFlow> {
  final Random _random = Random();
  int? _insertionIndex;
  String _catalogSignature = '';

  @override
  void initState() {
    super.initState();
    _refreshInsertionIndex();
  }

  @override
  void didUpdateWidget(covariant StoreCollectionFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = _signatureFor(widget.products, widget.collections);
    if (signature != _catalogSignature) {
      _refreshInsertionIndex();
    }
  }

  void _refreshInsertionIndex() {
    _catalogSignature = _signatureFor(widget.products, widget.collections);
    _insertionIndex = widget.collections.isEmpty
        ? null
        : randomCollectionInsertionIndex(widget.products.length, _random);
  }

  String _signatureFor(
    List<ProductModel> products,
    List<SectionModel> collections,
  ) {
    return '${products.map((product) => product.id).join(',')}|'
        '${collections.map((collection) => collection.id).join(',')}';
  }

  @override
  Widget build(BuildContext context) {
    final insertionIndex = _insertionIndex;
    if (insertionIndex == null || widget.collections.isEmpty) {
      return ProductSectionWidget(products: widget.products);
    }

    final before = widget.products.take(insertionIndex).toList();
    final after = widget.products.skip(insertionIndex).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductSectionWidget(products: before),
        const SizedBox(height: 22),
        StoreCollectionCarousel(
          storeId: widget.storeId,
          collections: widget.collections,
        ),
        const SizedBox(height: 22),
        ProductSectionWidget(products: after, showViewToggle: false),
      ],
    );
  }
}

class StoreCollectionCarousel extends StatelessWidget {
  const StoreCollectionCarousel({
    super.key,
    required this.collections,
    required this.storeId,
  });

  final List<SectionModel> collections;
  final String storeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Collections à découvrir',
                  style: AppTextStyles.sectionTitle(context),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CollectionPage(storeId: storeId),
                  ),
                ),
                child: const Text('Tout voir'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: collections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final collection = collections[index];
              return TweenAnimationBuilder<double>(
                key: ValueKey(collection.id),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 280 + index * 70),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _CollectionCarouselCard(
                  collection: collection,
                  storeId: storeId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CollectionCarouselCard extends StatelessWidget {
  const _CollectionCarouselCard({
    required this.collection,
    required this.storeId,
  });

  final SectionModel collection;
  final String storeId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      child: Material(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CollectionPage(storeId: storeId)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent(context).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.collections_outlined,
                    color: AppColors.iconAccent(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    collection.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(fontSize: 12, fontWeight: FontWeight.w800),
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
