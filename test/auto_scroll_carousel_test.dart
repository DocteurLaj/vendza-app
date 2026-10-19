import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/shared/widgets/carousel/auto_scroll_carousel.dart';

void main() {
  testWidgets('list helper does not start after being disposed', (
    tester,
  ) async {
    final controller = ScrollController();
    var indexChanges = 0;
    final helper = AutoScrollListHelper(
      scrollController: controller,
      itemCount: 2,
      itemExtent: 100,
      onIndexChanged: (_) => indexChanges++,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          controller: controller,
          scrollDirection: Axis.horizontal,
          itemExtent: 100,
          itemCount: 2,
          itemBuilder: (_, _) => const SizedBox(),
        ),
      ),
    );

    helper.startAfterLayout();
    helper.dispose();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(indexChanges, 0);
    controller.dispose();
  });

  testWidgets('page helper does not start after being disposed', (
    tester,
  ) async {
    final controller = PageController();
    var pageChanges = 0;
    final helper = AutoScrollPageHelper(
      controller: controller,
      itemCount: 2,
      onVirtualPageChanged: (_) => pageChanges++,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PageView.builder(
          controller: controller,
          itemCount: 2,
          itemBuilder: (_, _) => const SizedBox(),
        ),
      ),
    );

    helper.startAfterLayout();
    helper.dispose();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(pageChanges, 0);
    controller.dispose();
  });
}
