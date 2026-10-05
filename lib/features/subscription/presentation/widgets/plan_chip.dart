import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/features/subscription/presentation/pages/subscription_page.dart';

/// A compact, inline plan indicator.
///
/// Reads from [activeSubscriptionStore] (no extra API call when already loaded).
/// If the store is empty on first build, triggers a silent refresh once.
/// Tapping opens the subscription page.
class PlanChip extends StatefulWidget {
  const PlanChip({super.key, this.showUpgradeHint = false});

  /// If true, adds a subtle "Améliorer" hint when on the free plan.
  final bool showUpgradeHint;

  @override
  State<PlanChip> createState() => _PlanChipState();
}

class _PlanChipState extends State<PlanChip> {
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    // If store already has data, nothing to do.
    // Otherwise trigger a silent refresh once so the chip can display.
    if (activeSubscriptionStore.value == null) {
      _silentRefresh();
    }
  }

  void _silentRefresh() {
    if (_tried) return;
    _tried = true;
    refreshActiveSubscription().ignore();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: activeSubscriptionStore,
      builder: (context, ctx, _) {
        // Still loading — show a minimal placeholder
        if (ctx == null) {
          return const SizedBox(height: 18);
        }

        final plan = ctx.plan;
        final isFree = plan.isFree;
        final accent = AppColors.accent(context);
        final chipColor =
            isFree ? AppColors.textSecondary(context) : accent;

        return GestureDetector(
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPage()),
          ),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFree
                    ? Icons.workspace_premium_outlined
                    : Icons.workspace_premium_rounded,
                size: 13,
                color: chipColor,
              ),
              const SizedBox(width: 4),
              Text(
                isFree ? 'Plan Gratuit' : plan.title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: chipColor,
                  height: 1.2,
                ),
              ),
              if (widget.showUpgradeHint && isFree) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Améliorer',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 13,
                  color: chipColor.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
