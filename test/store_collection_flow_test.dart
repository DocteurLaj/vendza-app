import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/store/presentation/widgets/store_collection_flow.dart';

void main() {
  test('random insertion index stays inside the product flow', () {
    final random = Random(7);

    final index = randomCollectionInsertionIndex(12, random);

    expect(index, inInclusiveRange(1, 11));
  });

  test('catalogues with fewer than two products do not insert collections', () {
    expect(randomCollectionInsertionIndex(0, Random(1)), isNull);
    expect(randomCollectionInsertionIndex(1, Random(1)), isNull);
  });
}
