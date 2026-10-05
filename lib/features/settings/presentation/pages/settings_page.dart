import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/session/subscription_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/settings/presentation/pages/settings_detail_pages.dart';
import 'package:vendza/features/subscription/presentation/pages/subscription_page.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: const VendzaPageHeader.root(
        title: 'Paramètres',
        subtitle: 'Préférences, confidentialité et support',
        icon: Icons.settings_outlined,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            ResponsiveContent(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SubscriptionSettingsTile(),
                  const SizedBox(height: 18),
                  const _SettingsSectionTitle(title: "Preferences"),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: "Notifications",
                    subtitle: "Autoriser ou couper les notifications",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: "Apparence",
                    subtitle: "Systeme, clair ou sombre",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppearanceSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: "Confidentialite",
                    subtitle: "Securite et visibilite du compte",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const _SettingsSectionTitle(title: "Assistance"),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.support_agent_outlined,
                    title: "Support",
                    subtitle: "Contacter nos agents",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.feedback_outlined,
                    title: "Feedback",
                    subtitle: "Nous faire un retour",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: "A propos de l'application",
                    subtitle: "Informations sur Vendza",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const _VersionTile(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionLabel(context));
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppInteractive(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      enableHoverElevation: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accent(context).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: AppColors.accent(context), size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle(context)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.subtitle(context)),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.accent(context).withValues(alpha: 0.55),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            color: AppColors.accent(context),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Version de l'application",
              style: AppTextStyles.body(
                context,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Text("v1.0.0", style: AppTextStyles.label(context)),
        ],
      ),
    );
  }
}

// ── Subscription tile ──────────────────────────────────────────────────────

class _SubscriptionSettingsTile extends StatelessWidget {
  const _SubscriptionSettingsTile();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: activeSubscriptionStore,
      builder: (context, ctx, _) {
        final plan = ctx?.plan;
        final accent = AppColors.accent(context);
        final isFree = plan == null || plan.isFree;

        return AppInteractive(
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionPage()),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isFree
                  ? AppColors.card(context)
                  : accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFree
                    ? AppColors.border(context)
                    : accent.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFree
                        ? Icons.workspace_premium_outlined
                        : Icons.workspace_premium_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mon abonnement',
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan == null
                            ? 'Chargement…'
                            : isFree
                                ? 'Plan Gratuit · Passer à un plan supérieur'
                                : '${plan.title} · ${plan.formattedPrice}/mois',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
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
      },
    );
  }
}
