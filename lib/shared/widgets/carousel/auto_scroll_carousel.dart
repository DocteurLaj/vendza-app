import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vendza/core/constants/colors.dart';

class CarouselCircularDots extends StatelessWidget {
  const CarouselCircularDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.onDotTap,
  });

  final int count;
  final int activeIndex;
  final ValueChanged<int>? onDotTap;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count.clamp(0, 10), (index) {
        final isActive = activeIndex == index;
        return GestureDetector(
          onTap: onDotTap == null ? null : () => onDotTap!(index),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isActive ? 16 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class AutoScrollListHelper {
  AutoScrollListHelper({
    required this.scrollController,
    required this.itemCount,
    required this.itemExtent,
    required this.onIndexChanged,
    this.interval = const Duration(seconds: 3),
    this.resumeDelay = const Duration(seconds: 3),
    this.initialDelay = Duration.zero,
  });

  final ScrollController scrollController;
  final int itemCount;
  final double itemExtent;
  final ValueChanged<int> onIndexChanged;
  final Duration interval;
  final Duration resumeDelay;
  final Duration initialDelay;

  Timer? _timer;
  Timer? _initialTimer;
  Timer? _resumeTimer;
  VoidCallback? _scrollListener;
  bool userInteracting = false;
  bool _isAutoAdvancing = false;
  int activeIndex = 0;

  void startAfterLayout() {
    if (itemCount <= 1) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      _schedulePeriodicStart();
    });
  }

  void _schedulePeriodicStart() {
    _timer?.cancel();
    _initialTimer?.cancel();

    _initialTimer = Timer(initialDelay, () {
      if (itemCount <= 1) return;

      _advance();
      _timer?.cancel();
      _timer = Timer.periodic(interval, (_) => _advance());
    });
  }

  void attachListener() {
    _scrollListener = syncIndexFromOffset;
    scrollController.addListener(_scrollListener!);
  }

  void onUserScrollStart() {
    userInteracting = true;
    _resumeTimer?.cancel();
  }

  void onUserScrollEnd() {
    syncIndexFromOffset();
    _resumeTimer?.cancel();
    _resumeTimer = Timer(resumeDelay, () {
      userInteracting = false;
    });
  }

  void goToIndex(int index) {
    if (!scrollController.hasClients || itemCount <= 1) return;

    final targetIndex = index.clamp(0, itemCount - 1);
    final targetOffset = _offsetForIndex(targetIndex);

    onUserScrollStart();
    activeIndex = targetIndex;
    onIndexChanged(targetIndex);

    _isAutoAdvancing = true;
    scrollController
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _isAutoAdvancing = false);

    onUserScrollEnd();
  }

  double _offsetForIndex(int index) {
    if (!scrollController.hasClients) return index * itemExtent;
    return (index * itemExtent).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );
  }

  void _advance() {
    if (userInteracting ||
        _isAutoAdvancing ||
        !scrollController.hasClients ||
        itemCount <= 1) {
      return;
    }

    final nextIndex = (activeIndex + 1) % itemCount;
    final targetOffset = _offsetForIndex(nextIndex);

    activeIndex = nextIndex;
    onIndexChanged(nextIndex);

    _isAutoAdvancing = true;
    scrollController
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        )
        .whenComplete(() => _isAutoAdvancing = false);
  }

  void syncIndexFromOffset() {
    if (_isAutoAdvancing || !scrollController.hasClients || itemCount <= 1) {
      return;
    }

    final index = (scrollController.offset / itemExtent).round().clamp(
      0,
      itemCount - 1,
    );
    if (index != activeIndex) {
      activeIndex = index;
      onIndexChanged(index);
    }
  }

  void dispose() {
    _timer?.cancel();
    _initialTimer?.cancel();
    _resumeTimer?.cancel();
    if (_scrollListener != null) {
      scrollController.removeListener(_scrollListener!);
    }
  }
}

class AutoScrollPageHelper {
  AutoScrollPageHelper({
    required this.controller,
    required this.itemCount,
    required this.onVirtualPageChanged,
    this.interval = const Duration(seconds: 3),
    this.resumeDelay = const Duration(seconds: 3),
    this.initialDelay = Duration.zero,
    this.initialPage = 1000,
  });

  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onVirtualPageChanged;
  final Duration interval;
  final Duration resumeDelay;
  final Duration initialDelay;
  final int initialPage;

  Timer? _timer;
  Timer? _initialTimer;
  Timer? _resumeTimer;
  bool _userInteracting = false;
  late int currentPage;

  void startAfterLayout() {
    if (itemCount <= 1) return;
    currentPage = initialPage;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) return;
      _schedulePeriodicStart();
    });
  }

  void _schedulePeriodicStart() {
    _timer?.cancel();
    _initialTimer?.cancel();

    _initialTimer = Timer(initialDelay, () {
      if (itemCount <= 1) return;

      _advance();
      _timer?.cancel();
      _timer = Timer.periodic(interval, (_) => _advance());
    });
  }

  void onUserScrollStart() {
    _userInteracting = true;
    _resumeTimer?.cancel();
  }

  void onUserScrollEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(resumeDelay, () {
      _userInteracting = false;
    });
  }

  void updateCurrentPage(int page) {
    currentPage = page;
  }

  void goToItemIndex(int itemIndex) {
    if (itemCount <= 1 || !controller.hasClients) return;

    final target = itemIndex.clamp(0, itemCount - 1);
    onUserScrollStart();

    final basePage = currentPage - (currentPage % itemCount);
    currentPage = basePage + target;

    controller.animateToPage(
      currentPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    onVirtualPageChanged(currentPage);
    onUserScrollEnd();
  }

  void _advance() {
    if (_userInteracting || !controller.hasClients || itemCount <= 1) return;

    currentPage++;
    controller.animateToPage(
      currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    onVirtualPageChanged(currentPage);
  }

  void dispose() {
    _timer?.cancel();
    _initialTimer?.cancel();
    _resumeTimer?.cancel();
  }
}
