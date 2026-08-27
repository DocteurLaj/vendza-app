import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/main.dart';

void main() {
  testWidgets('Vendza application renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MyApp), findsOneWidget);
  });
}
