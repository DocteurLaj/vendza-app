import 'package:flutter/material.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/store/data/models/store_model.dart';
import 'package:vendza/features/store/presentation/widgets/store_widget.dart';
import 'package:vendza/shared/widgets/empty/empty_state_widget.dart';

class StoreListSection extends StatelessWidget {
  const StoreListSection({
    super.key,
    required this.title,
    required this.stores,
    required this.onStoreTap,
    this.emptyText = "Aucune boutique disponible",
  });

  final String title;
  final List<ListStoreModel> stores;
  final ValueChanged<ListStoreModel> onStoreTap;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(title, style: AppTextStyles.sectionTitle(context)),
          ),
          const SizedBox(height: 8),
          if (stores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: EmptyStateWidget(
                icon: Icons.storefront_outlined,
                title: title,
                message: emptyText,
                compact: true,
              ),
            )
          else
            ...stores.map(
              (store) => StoreWidget(
                name: store.name,
                description: store.description,
                imageUrl: store.imageUrl,
                status: store.rating.toString(),
                syncStatus: store.syncStatus,
                syncProgress: store.syncProgress,
                syncError: store.syncError,
                onRetrySync: store.syncStatus == EntitySyncStatus.error
                    ? () => catalogRepository.retryLocalCreate(
                        store.localId.isNotEmpty ? store.localId : store.id,
                      )
                    : null,
                onTap: () => onStoreTap(store),
              ),
            ),
        ],
      ),
    );
  }
}
