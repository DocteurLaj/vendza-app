import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/sync/entity_sync_status.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';
import 'package:vendza/shared/widgets/badge/attention_badge.dart';
import 'package:vendza/shared/widgets/media/smart_image.dart';
import 'package:vendza/shared/widgets/moderation/moderation_notice.dart';
import 'package:vendza/shared/widgets/sync/sync_status_strip.dart';

class StoreWidget extends StatelessWidget {
  const StoreWidget({
    super.key,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.status,
    required this.onTap,
    this.syncStatus = EntitySyncStatus.online,
    this.syncProgress = 1,
    this.syncError,
    this.onRetrySync,
    this.attentionCount = 0,
    this.attentionLabel,
    this.adminHidden = false,
    this.moderationReason,
    this.planLimitReached = false,
  });

  final String name;
  final String description;
  final String imageUrl;
  final String status;
  final VoidCallback onTap;
  final EntitySyncStatus syncStatus;
  final double syncProgress;
  final String? syncError;
  final VoidCallback? onRetrySync;
  final int attentionCount;
  final String? attentionLabel;
  final bool adminHidden;
  final String? moderationReason;
  final bool planLimitReached;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: AppInteractive(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        enableHoverElevation: true,
        child: Container(
          width: double.infinity,
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
                  child: imageUrl.isEmpty
                      ? const _StoreImagePlaceholder()
                      : SmartImage(
                          path: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: const _StoreImagePlaceholder(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
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
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 12,
                        height: 1.32,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (syncStatus.isPending) ...[
                      const SizedBox(height: 8),
                      SyncStatusStrip(
                        status: syncStatus,
                        progress: syncProgress,
                        errorMessage: syncError,
                        onRetry: onRetrySync,
                        compact: true,
                      ),
                    ],
                    if (adminHidden)
                      ModerationNotice(
                        title: 'Boutique bloquee',
                        reason: moderationReason,
                        compact: true,
                      ),
                    if (planLimitReached)
                      ModerationNotice(
                        title: 'Boutique désactivée',
                        reason:
                            'Votre abonnement Gratuit permet 1 boutique active. '
                            'Passez à un plan supérieur pour réactiver cette boutique.',
                        compact: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (attentionCount > 0) ...[
                    AttentionBadge(
                      count: attentionCount,
                      label: attentionLabel,
                    ),
                    const SizedBox(height: 8),
                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreImagePlaceholder extends StatelessWidget {
  const _StoreImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      color: AppColors.softSurface(context),
      alignment: Alignment.center,
      child: Icon(Icons.storefront_outlined, color: AppColors.accent(context)),
    );
  }
}
