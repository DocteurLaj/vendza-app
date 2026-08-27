import 'package:flutter/material.dart';
import 'package:vendza/features/collection/data/services/data_exemple.dart';
import 'package:vendza/features/collection/presentation/pages/collection_produit_page.dart';
import 'package:vendza/features/collection/presentation/widgets/add_collection_dialog.dart';
import 'package:vendza/features/collection/presentation/widgets/collection_product_stack_preview.dart';
import 'package:vendza/shared/widgets/bouton/list_button_section.dart';
import 'package:vendza/shared/widgets/dialog/confirm_delete_dialog.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({
    super.key,
    required this.storeId,
    this.canManage = false,
  });

  final String storeId;
  final bool canManage;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    collectionRepository.refreshCollections(widget.storeId).catchError((
      Object error,
    ) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    });
  }

  bool get _selectionMode => widget.canManage && _selectedIds.isNotEmpty;

  Future<void> _showAddDialog(BuildContext context) async {
    final name = await showAddCollectionDialog(context);
    if (!mounted || name == null || name.trim().isEmpty) return;

    final messenger = ScaffoldMessenger.of(this.context);
    try {
      await collectionRepository.createCollection(
        storeId: widget.storeId,
        name: name.trim(),
      );
      if (mounted) setState(() {});
    } on Object catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
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
        ..addAll(collections.map((collection) => collection.id));
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showConfirmDeleteDialog(
      context: context,
      title: "Supprimer les collections",
      message:
          "Es-tu sûr de vouloir supprimer $count collection(s) ? Les produits assignés seront retirés de ces collections.",
    );

    if (!confirmed) return;

    try {
      await collectionRepository.deleteCollections(_selectedIds);
      if (!mounted) return;
      setState(() => _selectedIds.clear());
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: collectionRevision,
      builder: (context, _, _) {
        return Scaffold(
          appBar: _selectionMode
              ? buildSelectionAppBar(
                  context: context,
                  selectedCount: _selectedIds.length,
                  onCancel: () => setState(() => _selectedIds.clear()),
                  onSelectAll: _selectAll,
                  onDelete: _deleteSelected,
                )
              : AppBar(title: const Text("Collection")),
          body: ListButtonSection(
            icon: Icons.collections_outlined,
            items: collections,
            emptyTitle: "Aucune collection",
            emptyMessage: widget.canManage
                ? "Crée une collection pour regrouper tes produits."
                : "Aucune collection n'est disponible pour le moment.",
            selectedIds: _selectedIds,
            leadingBuilder: (item) => CollectionProductStackPreview(
              products: collectionProducts[item.id] ?? const [],
            ),
            onLongPress: (collection) => _toggleSelection(collection.id),
            onPressed: (collection) async {
              if (_selectionMode) {
                _toggleSelection(collection.id);
                return;
              }

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CollectionProduitPage(
                    collection,
                    canManage: widget.canManage,
                  ),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
          floatingActionButton: widget.canManage && !_selectionMode
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text("Collection"),
                )
              : null,
        );
      },
    );
  }
}
