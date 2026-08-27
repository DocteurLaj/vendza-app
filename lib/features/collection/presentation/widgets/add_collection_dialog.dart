import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

Future<String?> showAddCollectionDialog(BuildContext context) {
  return showAppPopup<String>(
    context: context,
    size: PopupSize.medium,
    builder: (context) => const AddCollectionDialog(),
  );
}

class AddCollectionDialog extends StatefulWidget {
  const AddCollectionDialog({super.key});

  @override
  State<AddCollectionDialog> createState() => _AddCollectionDialogState();
}

class _AddCollectionDialogState extends State<AddCollectionDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createCollection() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Entre le nom de la collection';
      });
      return;
    }

    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nouvelle collection',
              style: AppTextStyles.sectionTitle(
                context,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoute une collection pour regrouper les produits du store.',
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _createCollection(),
              decoration: InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Nouveautes',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: AppColors.accent(context)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppPopupActions(
              cancelLabel: 'Annuler',
              confirmLabel: 'Creer',
              onCancel: () => Navigator.pop(context),
              onConfirm: _createCollection,
              borderRadius: 9,
            ),
          ],
        ),
      ),
    );
  }
}
