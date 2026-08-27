import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/product/product_price_text.dart';

Future<List<ProductModel>?> showAssignProductsDialog({
  required BuildContext context,
  required List<ProductModel> products,
  required List<ProductModel> selectedProducts,
  String title = 'Ajouter des produits',
  String subtitle = 'Choisis les produits à assigner.',
}) {
  return showAppPopup<List<ProductModel>>(
    context: context,
    size: PopupSize.large,
    scrollable: true,
    builder: (context) => AssignProductsDialog(
      products: products,
      selectedProducts: selectedProducts,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class AssignProductsDialog extends StatefulWidget {
  const AssignProductsDialog({
    super.key,
    required this.products,
    required this.selectedProducts,
    required this.title,
    required this.subtitle,
  });

  final List<ProductModel> products;
  final List<ProductModel> selectedProducts;
  final String title;
  final String subtitle;

  @override
  State<AssignProductsDialog> createState() => _AssignProductsDialogState();
}

class _AssignProductsDialogState extends State<AssignProductsDialog> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedProducts.map((product) => product.id).toSet();
  }

  void _toggleProduct(ProductModel product, bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _selectedIds.add(product.id);
      } else {
        _selectedIds.remove(product.id);
      }
    });
  }

  void _confirmSelection() {
    final List<ProductModel> selectedProducts = widget.products
        .where((product) => _selectedIds.contains(product.id))
        .toList();

    Navigator.pop(context, selectedProducts);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AssignProductsHeader(
              title: widget.title,
              subtitle: widget.subtitle,
              selectedCount: _selectedIds.length,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: widget.products.isEmpty
                  ? const Center(
                      child: EmptyStateWidget(
                        icon: Icons.inventory_2_outlined,
                        title: 'Aucun produit disponible',
                        message:
                            'Ajoute d\'abord des produits dans ta boutique.',
                        compact: true,
                      ),
                    )
                  : ListView.separated(
                      itemCount: widget.products.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final ProductModel product = widget.products[index];
                        final bool isSelected = _selectedIds.contains(
                          product.id,
                        );

                        return _SelectableProductTile(
                          product: product,
                          isSelected: isSelected,
                          onTap: () => _toggleProduct(product, !isSelected),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            AppPopupActions(
              cancelLabel: 'Annuler',
              confirmLabel: 'Valider',
              onCancel: () => Navigator.pop(context),
              onConfirm: _confirmSelection,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignProductsHeader extends StatelessWidget {
  const _AssignProductsHeader({
    required this.title,
    required this.subtitle,
    required this.selectedCount,
  });

  final String title;
  final String subtitle;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accent(context).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: AppColors.iconAccent(context),
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle(
                  context,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.body(context)),
              if (selectedCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$selectedCount sélectionné(s)',
                  style: TextStyle(
                    color: AppColors.accent(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectableProductTile extends StatelessWidget {
  const _SelectableProductTile({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final ProductModel product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      enableHoverElevation: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent(context).withValues(alpha: 0.12)
              : AppColors.searchSurface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.accent(context)
                : AppColors.border(context),
            width: isSelected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            _ProductSelectionThumbnail(imageUrl: product.imageurl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.isEmpty
                        ? 'Sans catégorie'
                        : product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ProductPriceText(
                    product.price,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _SelectionMark(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final checkColor = AppColors.isDark(context)
        ? AppColors.darkBackground
        : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? accent : AppColors.card(context),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isSelected ? accent : accent.withValues(alpha: 0.35),
          width: 1.3,
        ),
      ),
      child: isSelected ? Icon(Icons.check, color: checkColor, size: 17) : null,
    );
  }
}

class _ProductSelectionThumbnail extends StatelessWidget {
  const _ProductSelectionThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 52,
        height: 52,
        color: AppColors.card(context),
        child: imageUrl.isEmpty
            ? _ProductImagePlaceholder()
            : Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ProductImagePlaceholder(),
              ),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.inventory_2_outlined,
      color: AppColors.iconAccent(context),
      size: 23,
    );
  }
}
