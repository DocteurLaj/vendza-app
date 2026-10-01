import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/site_links.dart';

class ModerationNotice extends StatelessWidget {
  const ModerationNotice({
    super.key,
    required this.title,
    required this.reason,
    this.compact = false,
  });

  final String title;
  final String? reason;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cleanReason = reason?.trim();
    final reasonText = cleanReason == null || cleanReason.isEmpty
        ? 'Motif non precise. Contactez le support pour plus de details.'
        : cleanReason;
    final danger = AppColors.isDark(context)
        ? const Color(0xFFFFAB91)
        : const Color(0xFFC62828);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: compact ? 8 : 12),
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: danger.withValues(
          alpha: AppColors.isDark(context) ? 0.13 : 0.08,
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: danger.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.gpp_maybe_outlined,
                color: danger,
                size: compact ? 16 : 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: danger,
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Motif : $reasonText',
            maxLines: compact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: compact ? 11 : 12.5,
              height: 1.32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  SiteLinks.openUri(SiteLinks.mailtoSupport(subject: title)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, compact ? 28 : 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.accent(context),
                textStyle: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              icon: const Icon(Icons.support_agent_outlined, size: 16),
              label: const Text('Contacter le support'),
            ),
          ),
        ],
      ),
    );
  }
}
