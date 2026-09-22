import 'package:flutter/material.dart';

enum ProductViewMode { grid, list }

extension ProductViewModePresentation on ProductViewMode {
  String get label => switch (this) {
    ProductViewMode.grid => 'Grille',
    ProductViewMode.list => 'Liste',
  };

  String get iconName => switch (this) {
    ProductViewMode.grid => 'grid',
    ProductViewMode.list => 'list',
  };

  IconData get icon => switch (this) {
    ProductViewMode.grid => Icons.grid_view_rounded,
    ProductViewMode.list => Icons.view_list_rounded,
  };

  ProductViewMode get toggled => switch (this) {
    ProductViewMode.grid => ProductViewMode.list,
    ProductViewMode.list => ProductViewMode.grid,
  };
}

final productViewModeStore = ValueNotifier<ProductViewMode>(
  ProductViewMode.grid,
);
