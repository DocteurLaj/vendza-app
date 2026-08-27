import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';

class StoreCatalogCard extends StatelessWidget {
  const StoreCatalogCard({super.key, required this.store, required this.onTap});

  final StoreModel store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      enableHoverElevation: true,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.025),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(
                width: 66,
                height: 66,
                child: store.image.isEmpty
                    ? const _StoreCatalogPlaceholder()
                    : SmartImage(
                        path: store.image,
                        fit: BoxFit.cover,
                        errorWidget: const _StoreCatalogPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    store.getDescription(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 12,
                      height: 1.32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.softSurface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.accent(context),
                size: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreCatalogPlaceholder extends StatelessWidget {
  const _StoreCatalogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.softSurface(context),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        color: AppColors.accent(context),
        size: 28,
      ),
    );
  }
}
