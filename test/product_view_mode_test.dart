import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/shared/widgets/product/product_view_mode.dart';

void main() {
  group('product view mode', () {
    test('offers compact grid and list labels', () {
      expect(ProductViewMode.grid.label, 'Grille');
      expect(ProductViewMode.list.label, 'Liste');
      expect(ProductViewMode.grid.iconName, 'grid');
      expect(ProductViewMode.list.iconName, 'list');
    });

    test('toggles between grid and list', () {
      expect(ProductViewMode.grid.toggled, ProductViewMode.list);
      expect(ProductViewMode.list.toggled, ProductViewMode.grid);
    });
  });
}
