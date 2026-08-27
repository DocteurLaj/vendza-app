import 'package:flutter/material.dart';
import 'package:vendza/core/constants/app_interaction_tokens.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

enum HomeSearchFilter { all, products, stores }

class HomeSearchFilterBar extends StatelessWidget {
  const HomeSearchFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.productCount,
    required this.storeCount,
  });

  final HomeSearchFilter selected;
  final ValueChanged<HomeSearchFilter> onChanged;
  final int productCount;
  final int storeCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tout (${productCount + storeCount})',
            isSelected: selected == HomeSearchFilter.all,
            onSelected: () => onChanged(HomeSearchFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Produits ($productCount)',
            isSelected: selected == HomeSearchFilter.products,
            onSelected: () => onChanged(HomeSearchFilter.products),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Stores ($storeCount)',
            isSelected: selected == HomeSearchFilter.stores,
            onSelected: () => onChanged(HomeSearchFilter.stores),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final selectedLabelColor = AppColors.isDark(context)
        ? AppColors.darkBackground
        : Colors.white;

    return AppInteractive(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: AppInteractionTokens.duration,
        curve: AppInteractionTokens.curve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accent : AppColors.card(context),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? accent : AppColors.border(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? selectedLabelColor
                : AppColors.textPrimary(context),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
