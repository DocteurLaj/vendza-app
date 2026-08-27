import 'package:flutter/material.dart';
import 'package:vendza/features/cathegory/data/services/data_exemple.dart';
import 'package:vendza/features/cathegory/presentation/pages/cathegory_produit_page.dart';
import 'package:vendza/features/cathegory/presentation/widgets/cathegory_product_preview.dart';
import 'package:vendza/features/cathegory/presentation/widgets/add_cathegory_dialog.dart';
import 'package:vendza/features/store/data/services/data_exemple.dart'
    as store_data;
import 'package:vendza/shared/widgets/bouton/list_button_section.dart';
import 'package:vendza/shared/widgets/dialog/confirm_delete_dialog.dart';

class CathegoryPage extends StatefulWidget {
  const CathegoryPage({super.key, this.canManage = false});

  final bool canManage;

  @override
  State<CathegoryPage> createState() => _CathegoryPageState();
}

class _CathegoryPageState extends State<CathegoryPage> {
  final Set<String> _selectedIds = {};

  bool get _selectionMode => widget.canManage && _selectedIds.isNotEmpty;

  Future<void> _showAddDialog(BuildContext context) async {
    final category = await showAddCathegoryDialog(context);
    if (category == null) return;
    setState(() {
      categories.add(category);
    });
  }

  void _toggleSelection(String id) {
    if (!widget.canManage) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(categories.map((category) => category.id));
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showConfirmDeleteDialog(
      context: context,
      title: "Supprimer les catégories",
      message:
          "Es-tu sûr de vouloir supprimer $count catégorie(s) ? Cette action ne peut pas être annulée.",
    );

    if (!confirmed) return;

    setState(() {
      final selectedNames = categories
          .where((category) => _selectedIds.contains(category.id))
          .map((category) => category.name)
          .toSet();

      for (int index = 0; index < store_data.products.length; index++) {
        final product = store_data.products[index];
        if (selectedNames.contains(product.category)) {
          store_data.products[index] = product.copyWith(category: "");
        }
      }

      categories.removeWhere((category) => _selectedIds.contains(category.id));
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectionMode
          ? buildSelectionAppBar(
              context: context,
              selectedCount: _selectedIds.length,
              onCancel: () => setState(() => _selectedIds.clear()),
              onSelectAll: _selectAll,
              onDelete: _deleteSelected,
            )
          : AppBar(title: const Text("Catégorie")),
      body: ListButtonSection(
        icon: Icons.category_outlined,
        items: categories,
        emptyTitle: "Aucune catégorie",
        emptyMessage: widget.canManage
            ? "Crée une catégorie pour organiser les produits de ta boutique."
            : "Aucune catégorie n'est disponible pour le moment.",
        selectedIds: _selectedIds,
        leadingBuilder: (category) => CathegoryProductPreview(
          products: store_data.products
              .where((product) => product.category == category.name)
              .toList(),
        ),
        onLongPress: (category) => _toggleSelection(category.id),
        onPressed: (category) async {
          if (_selectionMode) {
            _toggleSelection(category.id);
            return;
          }

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CathegoryProduitPage(category, canManage: widget.canManage),
            ),
          );
          if (mounted) setState(() {});
        },
      ),
      floatingActionButton: widget.canManage && !_selectionMode
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Cathegorie"),
            )
          : null,
    );
  }
}
