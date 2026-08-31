import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/sync/entity_sync_status.dart';

class SyncStatusStrip extends StatelessWidget {
  const SyncStatusStrip({
    super.key,
    required this.status,
    this.progress = 0,
    this.errorMessage,
    this.onRetry,
    this.compact = false,
  });

  final EntitySyncStatus status;
  final double progress;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!status.isPending) return const SizedBox.shrink();

    final showBar = status == EntitySyncStatus.syncing ||
        status == EntitySyncStatus.queued ||
        status == EntitySyncStatus.waitingNetwork;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                status.labelWithProgress(progress),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: status == EntitySyncStatus.error
                      ? const Color(0xFFB3261E)
                      : AppColors.accent(context),
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (status == EntitySyncStatus.error && onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Réessayer'),
              ),
          ],
        ),
        if (showBar) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: status.barValue(progress),
              minHeight: compact ? 4 : 6,
              backgroundColor: AppColors.border(context),
              color: AppColors.accent(context),
            ),
          ),
        ],
        if (!compact && errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            errorMessage!.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB3261E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
