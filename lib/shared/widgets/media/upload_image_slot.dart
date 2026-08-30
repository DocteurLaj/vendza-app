import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/upload/image_upload_controller.dart';
import 'package:vendza/features/store/presentation/widgets/custom_image_selector.dart';

class UploadImageSlot extends StatelessWidget {
  const UploadImageSlot({
    super.key,
    required this.controller,
    required this.emptyTitle,
    this.filledTitle = "Remplacer l'image",
    this.subtitle = "Appuyez pour choisir une image",
    this.height = 168,
    this.emptyIcon = Icons.add_a_photo_outlined,
    this.filledIcon = Icons.edit_outlined,
    this.enabled = true,
  });

  final ImageUploadController controller;
  final String emptyTitle;
  final String filledTitle;
  final String subtitle;
  final double height;
  final IconData emptyIcon;
  final IconData filledIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasImage = controller.hasImage;
        final status = controller.status;
        return Stack(
          children: [
            CustomImageSelector(
              title: hasImage ? filledTitle : emptyTitle,
              subtitle: switch (status) {
                ImageUploadStatus.uploading => "Importation en cours...",
                ImageUploadStatus.failed =>
                  controller.errorMessage ?? "Echec de l'importation.",
                ImageUploadStatus.success => "Image prete",
                ImageUploadStatus.idle => subtitle,
              },
              imageUrl: controller.previewUrl,
              icon: hasImage ? filledIcon : emptyIcon,
              height: height,
              onTap: !enabled || controller.isUploading
                  ? null
                  : () => controller.pickAndUpload(context),
            ),
            if (status == ImageUploadStatus.uploading)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (status == ImageUploadStatus.failed)
              Positioned(
                right: 10,
                bottom: 10,
                child: TextButton.icon(
                  onPressed: enabled ? controller.retry : null,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.card(context),
                    foregroundColor: AppColors.accent(context),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Reessayer"),
                ),
              ),
          ],
        );
      },
    );
  }
}
