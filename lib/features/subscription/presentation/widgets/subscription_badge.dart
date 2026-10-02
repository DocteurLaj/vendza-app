import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';
import 'package:vendza/features/subscription/data/services/subscription_api_service.dart';
import 'package:vendza/features/subscription/presentation/pages/subscription_page.dart';

/// Loads and displays the current user's active plan as a tappable card.
/// Silently hides itself on error (unauthenticated, network, etc.).
class SubscriptionBadge extends StatefulWidget {
  const SubscriptionBadge({super.key});

  @override
  State<SubscriptionBadge> createState() => _SubscriptionBadgeState();
}

class _SubscriptionBadgeState extends State<SubscriptionBadge> {
  SubscriptionContextModel? _ctx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await subscriptionApiService.currentSubscription();
      if (mounted) setState(() { _ctx = result; _loading = false; });
    } on Object {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_ctx == null) return const SizedBox.shrink();

    final plan = _ctx!.plan;
    final accent = AppColors.accent(context);
    final isFree = plan.isFree;

    return GestureDetector(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const SubscriptionPage()),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isFree
              ? AppColors.card(context)
              : accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFree
                ? AppColors.border(context)
                : accent.withValues(alpha: 0.24),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isFree
                  ? Icons.workspace_premium_outlined
                  : Icons.workspace_premium_rounded,
              color: isFree ? AppColors.textSecondary(context) : accent,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFree ? 'Plan gratuit' : plan.title,
                    style: AppTextStyles.body(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: isFree ? AppColors.textPrimary(context) : accent,
                    ),
                  ),
                  Text(
                    isFree
                        ? 'Passez à un plan supérieur'
                        : plan.formattedPrice,
                    style: AppTextStyles.body(context).copyWith(
                      fontSize: 11.5,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary(context),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
