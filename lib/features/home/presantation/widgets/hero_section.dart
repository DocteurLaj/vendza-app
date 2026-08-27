import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/sizes.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  late final PageController _controller;
  Timer? _timer;

  int currentPage = 1000;
  bool isUserInteracting = false;

  final int itemCount = 5;

  @override
  void initState() {
    super.initState();

    _controller = PageController(
      viewportFraction: 0.8,
      initialPage: currentPage,
    );

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!isUserInteracting && _controller.hasClients) {
        currentPage++;

        _controller.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ éviter crash
    _controller.dispose(); // ✅ éviter fuite mémoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: GestureDetector(
            onPanDown: (_) => isUserInteracting = true,
            onPanCancel: () => isUserInteracting = false,
            onPanEnd: (_) => isUserInteracting = false,
            child: PageView.builder(
              controller: _controller,
              itemCount: null, // 🔥 important pour infini
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final realIndex = index % itemCount;

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double scale = 1.0;

                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      double page = _controller.page ?? currentPage.toDouble();
                      scale = (1 - (page - index).abs() * 0.2).clamp(0.8, 1.0);
                    }

                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                      ),
                      child: Center(
                        child: Text(
                          "Item $realIndex",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        //  DOTS INDICATOR
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(itemCount, (index) {
            int activeIndex = currentPage % itemCount;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: activeIndex == index ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: activeIndex == index ? AppColors.primary : Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}
