import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/product/presentation/widgets/product_detail_widgets.dart';

void main() {
  testWidgets('multi-image gallery exposes a visible position and swipe hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: ProductDetailHero(
            imageUrl: 'https://cdn.example.com/one.jpg',
            images: [
              'https://cdn.example.com/one.jpg',
              'https://cdn.example.com/two.jpg',
              'https://cdn.example.com/three.jpg',
            ],
            showFullImage: true,
            indicatorBottom: 124,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byIcon(Icons.swipe_rounded), findsOneWidget);
    expect(find.byType(ProductDetailHeroDot), findsNWidgets(3));

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
  });
}
