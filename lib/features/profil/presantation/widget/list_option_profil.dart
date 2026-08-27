import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/shared/widgets/dialog/logout_dialog.dart';
import 'package:vendza/features/profil/presantation/pages/my_profile_page.dart';
import 'package:vendza/features/settings/presentation/pages/settings_page.dart';
import 'package:vendza/features/store/presentation/pages/my_store_page.dart';
import 'package:vendza/shared/widgets/interaction/app_interactive.dart';

class ListOptionProfil extends StatelessWidget {
  const ListOptionProfil({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserStore.value;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          _ProfileSectionTitle(title: "Compte"),
          const SizedBox(height: 8),
          _ProfileOptionTile(
            icon: Icons.person_outline,
            title: "Mon profil",
            subtitle: user.email.isEmpty
                ? "Informations personnelles"
                : user.email,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyProfilePage()),
              );
            },
          ),
          const SizedBox(height: 10),
          _ProfileOptionTile(
            icon: Icons.storefront_outlined,
            title: "Mes stores",
            subtitle: "Gérer mes boutiques",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyStorePage()),
              );
            },
          ),
          const SizedBox(height: 10),
          _ProfileOptionTile(
            icon: Icons.settings_outlined,
            title: "Paramètres",
            subtitle: "Préférences de l’application",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(height: 18),
          _ProfileSectionTitle(title: "Session"),
          const SizedBox(height: 8),
          _ProfileOptionTile(
            icon: Icons.logout,
            title: "Se déconnecter",
            subtitle: "Quitter votre session actuelle",
            isDanger: true,
            onTap: () => showLogoutDialog(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: AppTextStyles.sectionLabel(context)),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final accentColor = isDanger
        ? const Color(0xFFD35454)
        : AppColors.accent(context);

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
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: accentColor, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(color: isDanger ? accentColor : null),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.subtitle(context)),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: accentColor.withValues(alpha: 0.45),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
