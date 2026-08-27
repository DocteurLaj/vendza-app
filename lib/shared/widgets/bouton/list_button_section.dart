import 'package:flutter/material.dart';
import 'package:vendza/shared/models/section_model.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/bouton/list_button.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';

class ListButtonSection extends StatelessWidget {
  const ListButtonSection({
    super.key,
    required this.icon,
    required this.items,
    required this.onPressed,
    this.leadingBuilder,
    this.onLongPress,
    this.selectedIds = const <String>{},
    this.emptyTitle = "Aucune donnée",
    this.emptyMessage = "Les éléments créés apparaîtront ici.",
  });

  final IconData icon;
  final List<SectionModel> items;
  final void Function(SectionModel item) onPressed;
  final Widget Function(SectionModel item)? leadingBuilder;
  final void Function(SectionModel item)? onLongPress;
  final Set<String> selectedIds;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ResponsiveContent(
        maxWidth: 920,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: EmptyStateWidget(
          icon: icon,
          title: emptyTitle,
          message: emptyMessage,
        ),
      );
    }

    return ResponsiveContent(
      maxWidth: 920,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.custom(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        childrenDelegate: SliverChildBuilderDelegate((
          BuildContext context,
          int index,
        ) {
          final item = items[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: ListButton(
              text: item.name,
              iconData: icon,
              leading: leadingBuilder?.call(item),
              isSelected: selectedIds.contains(item.id),
              onPressed: () => onPressed(item),
              onLongPress: onLongPress == null
                  ? null
                  : () => onLongPress!(item),
            ),
          );
        }, childCount: items.length),
      ),
    );
  }
}
