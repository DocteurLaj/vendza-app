import 'package:flutter/material.dart';
import 'package:vendza/core/constants/sizes.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/features/store/presentation/pages/store_detail_page.dart';
import 'package:vendza/shared/widgets/carousel/auto_scroll_carousel.dart';
import 'package:vendza/shared/widgets/carousel/carousel_scroll_scope.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/store/store_circle.dart';

class StoreSectionWidget extends StatefulWidget {
  const StoreSectionWidget({super.key, required this.stores});

  final List<StoreModel> stores;

  @override
  State<StoreSectionWidget> createState() => _StoreSectionWidgetState();
}

class _StoreSectionWidgetState extends State<StoreSectionWidget> {
  static const double _itemExtent = 96;

  late final ScrollController _scrollController;
  AutoScrollListHelper? _autoScroll;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    if (widget.stores.length > 1) {
      _autoScroll = AutoScrollListHelper(
        scrollController: _scrollController,
        itemCount: widget.stores.length,
        itemExtent: _itemExtent,
        initialDelay: Duration.zero,
        onIndexChanged: (index) {
          if (mounted) setState(() => _activeIndex = index);
        },
      )..attachListener();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoScroll?.startAfterLayout();
      });
    }
  }

  @override
  void dispose() {
    _autoScroll?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      maxWidth: 1120,
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: CarouselScrollScope(
              onUserScrollStart: () => _autoScroll?.onUserScrollStart(),
              onUserScrollEnd: () => _autoScroll?.onUserScrollEnd(),
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: carouselListPhysics,
                padding: EdgeInsets.symmetric(horizontal: AppSizes.padding),
                itemCount: widget.stores.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final store = widget.stores[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreDetailPage(store: store),
                        ),
                      );
                    },
                    child: StoreWidgetCircle(
                      name: store.name,
                      imageurl: store.image,
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.stores.length > 1) ...[
            const SizedBox(height: 8),
            CarouselCircularDots(
              count: widget.stores.length.clamp(0, 6),
              activeIndex: _activeIndex % widget.stores.length.clamp(1, 6),
              onDotTap: (index) => _autoScroll?.goToIndex(index),
            ),
          ],
        ],
      ),
    );
  }
}
