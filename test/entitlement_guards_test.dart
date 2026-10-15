import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/session/entitlement_guards.dart' as ent;
import 'package:vendza/core/session/subscription_store.dart';

void main() {
  setUp(() => clearSubscriptionSession());

  test('blocks creating a store when the free quota is reached', () {
    expect(ent.canCreateStore(currentCount: 0), isTrue);
    expect(ent.canCreateStore(currentCount: 1), isFalse);
  });

  test('blocks adding a product when the free quota is reached', () {
    expect(ent.canAddProduct(currentCount: 9), isTrue);
    expect(ent.canAddProduct(currentCount: 10), isFalse);
  });

  test(
    'blocks creating a collection when the plan has no collection quota',
    () {
      expect(ent.canCreateCollection(currentCount: 0), isFalse);
    },
  );
}
