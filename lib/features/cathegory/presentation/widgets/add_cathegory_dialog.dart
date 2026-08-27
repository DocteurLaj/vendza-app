import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/models/section_model.dart';
import 'package:vendza/shared/widgets/dialog/app_popup_actions.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';

Future<SectionModel?> showAddCathegoryDialog(BuildContext context) {
  return showAppPopup<SectionModel>(
    context: context,
    size: PopupSize.medium,
    builder: (context) => const AddCathegoryDialog(),
  );
}

class AddCathegoryDialog extends StatefulWidget {
  const AddCathegoryDialog({super.key});

  @override
  State<AddCathegoryDialog> createState() => _AddCathegoryDialogState();
}

class _AddCathegoryDialogState extends State<AddCathegoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createCathegory() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Entre le nom de la categorie';
      });
      return;
    }

    Navigator.pop(
      context,
      SectionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        imageUrl: '#',
      ),
    );
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
              'Nouvelle categorie',
              style: AppTextStyles.sectionTitle(
                context,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoute une categorie pour organiser les produits du store.',
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _createCathegory(),
              decoration: InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Accessoires',
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
              onConfirm: _createCathegory,
              borderRadius: 9,
            ),
          ],
        ),
      ),
    );
  }
}
