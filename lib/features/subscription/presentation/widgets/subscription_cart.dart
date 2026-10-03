import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/subscription/data/models/subscription_model.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

/// A self-contained subscription plan card.
///
/// Shows name, price, a compact feature list, and optional badges
/// (Recommandé, Actuel). Selected state uses a prominent accent border.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.sub,
    required this.isSelected,
    required this.onTap,
    this.isRecommended = false,
    this.isCurrent = false,
  });

  final SubscriptionModel sub;
  final bool isSelected;
  final VoidCallback onTap;
  /// Shows a "Recommandé" badge — set on the plan most sellers should pick.
  final bool isRecommended;
  /// Shows an "Actuel" badge — the user's active plan.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final isDark = AppColors.isDark(context);

    // Color tokens
    final borderColor = isSelected
        ? accent
        : AppColors.border(context);
    final bgColor = isSelected
        ? accent.withValues(alpha: 0.07)
        : AppColors.card(context);
    final borderWidth = isSelected ? 2.0 : 1.5;

    // Feature highlights — pick the 3 most relevant lines
    final highlights = _highlights(sub);

    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: name + badges ──────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      sub.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? accent
                            : AppColors.textPrimary(context),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isRecommended)
                    _Badge(
                      label: 'Recommandé',
                      color: accent,
                      textColor: isDark
                          ? AppColors.darkBackground
                          : Colors.white,
                    )
                  else if (isCurrent)
                    _Badge(
                      label: 'Actuel',
                      color: AppColors.textSecondary(context)
                          .withValues(alpha: 0.18),
                      textColor: AppColors.textSecondary(context),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Price ───────────────────────────────────────────────────
              if (sub.isFree)
                Text(
                  'Gratuit',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary(context),
                    height: 1.1,
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _priceAmount(sub),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary(context),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        sub.currency,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '/ mois',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ),

              // ── Promo subtitle (strikethrough) ──────────────────────────
              if (sub.subtitle.isNotEmpty && !sub.isFree) ...[
                const SizedBox(height: 4),
                Text(
                  sub.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFFFF8661)
                        : const Color(0xFFE05A2B),
                    decoration: TextDecoration.lineThrough,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border(context),
              ),
              const SizedBox(height: 10),

              // ── Feature highlights ──────────────────────────────────────
              ...highlights.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: isSelected
                            ? accent
                            : AppColors.textSecondary(context),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isSelected) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sélectionné',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the 3 most useful feature highlights for this plan.
  static List<String> _highlights(SubscriptionModel sub) {
    final ent = sub.entitlements;
    final lines = <String>[];

    final products = ent.intValue('max_products', 0);
    if (products > 0) {
      lines.add(
        products >= 300
            ? 'Jusqu\'à 300 produits actifs'
            : '$products produits actifs',
      );
    } else if (sub.isFree) {
      lines.add('10 produits actifs');
    }

    final collections = ent.intValue('max_collections', 0);
    if (collections > 0) {
      lines.add(
        collections >= 30
            ? 'Collections illimitées'
            : '$collections collections',
      );
    } else {
      lines.add('Sans collections');
    }

    if (ent.boolValue('has_variants')) {
      lines.add('Variantes produit');
    }

    if (ent.boolValue('has_banner')) {
      lines.add('Bannière de boutique');
    }

    final socials = ent.intValue('max_social_links', 1);
    if (socials > 1) {
      lines.add('$socials liens sociaux');
    }

    if (ent.boolValue('analytics_access')) {
      lines.add('Statistiques avancées');
    }

    // Keep at most 4 lines
    return lines.take(4).toList();
  }

  /// Price without the currency suffix.
  static String _priceAmount(SubscriptionModel sub) {
    if (sub.isFree) return '0';
    final p = sub.price;
    final intP = p.roundToDouble() == p ? p.toInt() : null;
    if (intP != null) {
      // Format with thousands separator
      final s = intP.toString();
      if (s.length > 3) {
        return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
      }
      return s;
    }
    return p.toStringAsFixed(0);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
