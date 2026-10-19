import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/site_links.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/session/notifications_enabled_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/core/theme/theme_controller.dart';
import 'package:vendza/features/auth/presantation/widgets/forgot_password_dialog.dart';
import 'package:vendza/features/settings/presentation/pages/delete_account_page.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';
import 'package:vendza/shared/widgets/layout/vendza_page_header.dart';

Future<void> _openExternalLink(BuildContext context, String value) async {
  final bool opened = await SiteLinks.open(value);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Impossible d'ouvrir ce lien")),
    );
  }
}

Future<void> _openExternalUri(BuildContext context, Uri uri) async {
  final bool opened = await SiteLinks.openUri(uri);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Impossible d'ouvrir ce lien")),
    );
  }
}

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notificationsEnabledStore,
      builder: (context, notificationsEnabled, _) {
        return _SettingsSimpleScaffold(
          title: "Notifications",
          children: [
            _SwitchSettingsTile(
              icon: Icons.notifications_outlined,
              title: "Autoriser les notifications",
              subtitle: notificationsEnabled
                  ? "Notifications activées : Vendza synchronise votre appareil pour les push."
                  : "Notifications coupées : les push sont désactivés sur cet appareil.",
              value: notificationsEnabled,
              onChanged: (enabled) {
                setNotificationsEnabledAndSync(enabled);
              },
            ),
          ],
        );
      },
    );
  }
}

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: const VendzaPageHeader.back(
        title: 'Apparence',
        subtitle: 'Thème clair, sombre ou système',
        icon: Icons.palette_outlined,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            ResponsiveContent(
              maxWidth: 720,
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeController,
                builder: (context, mode, _) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _settingsBoxDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _SettingsIcon(icon: Icons.palette_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SettingsText(
                                title: "Thème",
                                subtitle:
                                    "Choisir le mode clair, sombre ou système",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ThemeModeSelector(
                          selectedMode: mode,
                          onChanged: themeModeController.setMode,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text("Système"),
          icon: Icon(Icons.phone_android_outlined),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text("Clair"),
          icon: Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text("Sombre"),
          icon: Icon(Icons.dark_mode_outlined),
        ),
      ],
      selected: {selectedMode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.isDark(context)
                ? AppColors.darkBackground
                : Colors.white;
          }
          return AppColors.textSecondary(context);
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent(context);
          }
          return AppColors.elevatedSurface(context);
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: AppColors.border(context)),
        ),
      ),
    );
  }
}

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  // #107: there is no change-password/change-email API. The previous form
  // accepted input and then refused it; show the real, working flows instead.
  @override
  Widget build(BuildContext context) {
    final email = currentUserStore.value.email;
    return _SettingsSimpleScaffold(
      title: "Confidentialité",
      children: [
        _ActionSettingsTile(
          key: const ValueKey('privacy-account-email'),
          icon: Icons.email_outlined,
          title: "Email du compte",
          subtitle: email.isEmpty ? "Non renseigné" : email,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          key: const ValueKey('privacy-reset-password'),
          icon: Icons.lock_reset_outlined,
          title: "Changer mon mot de passe",
          subtitle: "Recevoir un lien de réinitialisation par email",
          onTap: () => showForgotPasswordDialog(context),
        ),
        const SizedBox(height: 24),
        _ActionSettingsTile(
          icon: Icons.policy_outlined,
          title: "Politique de confidentialité",
          subtitle: "Lire la page sur vendza.online",
          onTap: () => _openExternalLink(context, SiteLinks.privacy),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.gavel_outlined,
          title: "Conditions d'utilisation",
          subtitle: "Règles d'usage de Vendza",
          onTap: () => _openExternalLink(context, SiteLinks.terms),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          key: const ValueKey('delete-account-settings-entry'),
          icon: Icons.delete_forever_outlined,
          title: "Supprimer mon compte",
          subtitle: "Anonymisation définitive de vos données personnelles",
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
            );
          },
        ),
      ],
    );
  }
}

class SupportSettingsPage extends StatelessWidget {
  const SupportSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsSimpleScaffold(
      title: "Support",
      children: [
        _ActionSettingsTile(
          icon: Icons.email_outlined,
          title: "Email",
          subtitle: "Envoyer un message au support",
          trailing: SiteLinks.supportEmail,
          onTap: () => _openExternalUri(context, SiteLinks.mailtoSupport()),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.chat_outlined,
          title: "WhatsApp",
          subtitle: SiteLinks.hasSupportWhatsApp
              ? "Contacter un agent directement"
              : "Le numéro public n'est pas encore renseigné",
          trailing: SiteLinks.hasSupportWhatsApp
              ? SiteLinks.supportWhatsApp
              : null,
          onTap: () {
            final whatsapp = SiteLinks.whatsappUri;
            if (whatsapp != null) {
              _openExternalUri(context, whatsapp);
              return;
            }
            _openExternalLink(context, SiteLinks.contact);
          },
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.language_outlined,
          title: "Page contact",
          subtitle: "vendza.online/contact",
          onTap: () => _openExternalLink(context, SiteLinks.contact),
        ),
      ],
    );
  }
}

class FeedbackSettingsPage extends StatefulWidget {
  const FeedbackSettingsPage({super.key});

  @override
  State<FeedbackSettingsPage> createState() => _FeedbackSettingsPageState();
}

class _FeedbackSettingsPageState extends State<FeedbackSettingsPage> {
  final TextEditingController feedbackController = TextEditingController();
  bool _isSubmitting = false;

  bool get _canSubmit =>
      !_isSubmitting && feedbackController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    feedbackController.addListener(_onFeedbackChanged);
  }

  void _onFeedbackChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    feedbackController
      ..removeListener(_onFeedbackChanged)
      ..dispose();
    super.dispose();
  }

  // #107: feedback used to be discarded after a fake delay. It is now sent
  // to the support mailbox through the user's email app; the text is only
  // cleared once that app has actually opened.
  Future<void> _submitFeedback() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    final opened = await SiteLinks.openUri(
      SiteLinks.mailtoSupport(
        subject: 'Feedback Vendza',
        body: feedbackController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (opened) {
      feedbackController.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? "Votre application email s'est ouverte : envoyez le message pour transmettre votre retour."
              : "Aucune application email disponible. Écrivez-nous à ${SiteLinks.supportEmail}.",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSimpleScaffold(
      title: "Feedback",
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _settingsBoxDecoration(context),
          child: TextField(
            controller: feedbackController,
            minLines: 6,
            maxLines: 8,
            cursorColor: AppColors.accent(context),
            decoration: const InputDecoration(
              hintText: "Écrivez votre retour ici...",
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppBouton(
            text: "Envoyer par email",
            loadingText: "Ouverture...",
            onPressed: _submitFeedback,
            enabled: _canSubmit,
            isLoading: _isSubmitting,
          ),
        ),
      ],
    );
  }
}

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsSimpleScaffold(
      title: "À propos",
      children: [
        _ActionSettingsTile(
          icon: Icons.open_in_new_outlined,
          title: "À propos",
          subtitle: "C'est quoi Vendza",
          onTap: () => _openExternalLink(context, SiteLinks.about),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.menu_book_outlined,
          title: "En savoir plus",
          subtitle: "Boutiques, commandes, compte",
          onTap: () => _openExternalLink(context, SiteLinks.learnMore),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.gavel_outlined,
          title: "Conditions d'utilisation",
          subtitle: "Règles d'usage",
          onTap: () => _openExternalLink(context, SiteLinks.terms),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.policy_outlined,
          title: "Politique de confidentialité",
          subtitle: "Données et compte",
          onTap: () => _openExternalLink(context, SiteLinks.privacy),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.download_outlined,
          title: "Télécharger l'application",
          subtitle: "APK Android",
          onTap: () => _openExternalLink(context, SiteLinks.download),
        ),
      ],
    );
  }
}

class _SettingsSimpleScaffold extends StatelessWidget {
  const _SettingsSimpleScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: VendzaPageHeader.back(
        title: title,
        subtitle: 'Réglages Vendza',
        icon: _settingsHeaderIcon(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            ResponsiveContent(maxWidth: 720, child: Column(children: children)),
          ],
        ),
      ),
    );
  }
}

class _SwitchSettingsTile extends StatelessWidget {
  const _SwitchSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _settingsBoxDecoration(context),
      child: Row(
        children: [
          _SettingsIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: _SettingsText(title: title, subtitle: subtitle),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.success(context),
            activeTrackColor: AppColors.success(
              context,
            ).withValues(alpha: 0.26),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionSettingsTile extends StatelessWidget {
  const _ActionSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: _settingsBoxDecoration(context),
          child: Row(
            children: [
              _SettingsIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: _SettingsText(title: title, subtitle: subtitle),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    trailing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.label(context).copyWith(fontSize: 11),
                  ),
                ),
              ] else
                Icon(
                  Icons.chevron_right,
                  color: AppColors.accent(context).withValues(alpha: 0.55),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.accent(context).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppColors.accent(context), size: 21),
    );
  }
}

class _SettingsText extends StatelessWidget {
  const _SettingsText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.cardTitle(context)),
        const SizedBox(height: 3),
        Text(subtitle, style: AppTextStyles.subtitle(context)),
      ],
    );
  }
}

IconData _settingsHeaderIcon(String title) {
  return switch (title) {
    'Notifications' => Icons.notifications_outlined,
    'Confidentialité' => Icons.privacy_tip_outlined,
    'Support' => Icons.support_agent_outlined,
    'Feedback' => Icons.rate_review_outlined,
    'À propos' => Icons.info_outline,
    _ => Icons.settings_outlined,
  };
}

BoxDecoration _settingsBoxDecoration(BuildContext context) {
  return BoxDecoration(
    color: AppColors.card(context),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border(context)),
  );
}
