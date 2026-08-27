import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/dialog/show_app_popup.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

Future<ImageSource?> showImageSourceSheet({
  required BuildContext context,
  required String title,
}) {
  return showAppPopup<ImageSource>(
    context: context,
    size: PopupSize.small,
    builder: (context) => _ImageSourceSheet(title: title),
  );
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.pageTitle(context)),
            const SizedBox(height: 8),
            Text(
              'Choisissez une source',
              style: AppTextStyles.subtitle(context).copyWith(fontSize: 13),
            ),
            const SizedBox(height: 16),
            _SourceButton(
              icon: Icons.photo_library_outlined,
              label: 'Galerie',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _SourceButton(
              icon: Icons.photo_camera_outlined,
              label: 'Caméra',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.softSurface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.iconAccent(context)),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
