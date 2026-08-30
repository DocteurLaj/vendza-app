import 'package:flutter/material.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/site_links.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/core/session/notifications_enabled_store.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/core/theme/theme_controller.dart';
import 'package:vendza/features/settings/presentation/pages/delete_account_page.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

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
                  ? "Les notifications de Vendza sont activees"
                  : "Toutes les notifications de Vendza sont coupees",
              value: notificationsEnabled,
              onChanged: setNotificationsEnabled,
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
      appBar: AppBar(
        backgroundColor: AppColors.appBackground(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        centerTitle: true,
        title: Text("Apparence", style: AppTextStyles.pageTitle(context)),
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
                                title: "Theme",
                                subtitle:
                                    "Choisir le mode clair, sombre ou systeme",
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
          label: Text("Systeme"),
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
  late final TextEditingController emailController;
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool showPassword = false;
  bool _isSaving = false;

  bool get _canSave {
    final email = emailController.text.trim();
    final current = currentPasswordController.text;
    final next = newPasswordController.text;
    if (_isSaving) return false;
    if (!email.contains('@')) return false;
    if (current.isEmpty && next.isEmpty) return false;
    return current.isNotEmpty && next.length >= 8;
  }

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(
      text: currentUserStore.value.email,
    );
    emailController.addListener(_onFieldChanged);
    currentPasswordController.addListener(_onFieldChanged);
    newPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    emailController
      ..removeListener(_onFieldChanged)
      ..dispose();
    currentPasswordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    newPasswordController
      ..removeListener(_onFieldChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _savePrivacy() async {
    if (!_canSave || _isSaving) return;
    if (!NetworkStatus.ensureOnline(context)) return;
    setState(() => _isSaving = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Le changement de mot de passe depuis les paramètres n’est pas encore disponible. Utilisez Mot de passe oublié.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSimpleScaffold(
      title: "Confidentialite",
      children: [
        _InputSettingsTile(
          icon: Icons.email_outlined,
          title: "Email du compte",
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _InputSettingsTile(
          icon: Icons.lock_outline,
          title: "Mot de passe actuel",
          controller: currentPasswordController,
          obscureText: !showPassword,
        ),
        const SizedBox(height: 10),
        _InputSettingsTile(
          icon: Icons.password_outlined,
          title: "Nouveau mot de passe",
          controller: newPasswordController,
          obscureText: !showPassword,
        ),
        const SizedBox(height: 10),
        _SwitchSettingsTile(
          icon: Icons.visibility_outlined,
          title: "Afficher le mot de passe",
          subtitle: "Voir ou masquer les champs mot de passe",
          value: showPassword,
          onChanged: (value) {
            setState(() {
              showPassword = value;
            });
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppBouton(
            text: "Enregistrer",
            loadingText: "Enregistrement...",
            onPressed: _savePrivacy,
            enabled: _canSave,
            isLoading: _isSaving,
          ),
        ),
        const SizedBox(height: 24),
        _ActionSettingsTile(
          icon: Icons.policy_outlined,
          title: "Politique de confidentialite",
          subtitle: "Lire la page sur vendza.online",
          onTap: () => _openExternalLink(context, SiteLinks.privacy),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.gavel_outlined,
          title: "Conditions d'utilisation",
          subtitle: "Regles d'usage de Vendza",
          onTap: () => _openExternalLink(context, SiteLinks.terms),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          key: const ValueKey('delete-account-settings-entry'),
          icon: Icons.delete_forever_outlined,
          title: "Supprimer mon compte",
          subtitle: "Anonymisation definitive de vos donnees personnelles",
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
              : "Le numero public n'est pas encore renseigne",
          trailing: SiteLinks.hasSupportWhatsApp ? SiteLinks.supportWhatsApp : null,
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

  Future<void> _submitFeedback() async {
    if (!_canSubmit) return;
    if (!NetworkStatus.ensureOnline(context)) return;
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    feedbackController.clear();
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Merci pour votre feedback")));
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
              hintText: "Ecrivez votre retour ici...",
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: AppBouton(
            text: "Soumettre",
            loadingText: "Envoi...",
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
      title: "A propos",
      children: [
        _ActionSettingsTile(
          icon: Icons.open_in_new_outlined,
          title: "A propos",
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
          subtitle: "Regles d'usage",
          onTap: () => _openExternalLink(context, SiteLinks.terms),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.policy_outlined,
          title: "Politique de confidentialite",
          subtitle: "Donnees et compte",
          onTap: () => _openExternalLink(context, SiteLinks.privacy),
        ),
        const SizedBox(height: 10),
        _ActionSettingsTile(
          icon: Icons.download_outlined,
          title: "Telecharger l'application",
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
      appBar: AppBar(
        backgroundColor: AppColors.appBackground(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: AppTextStyles.pageTitle(context)),
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

class _InputSettingsTile extends StatelessWidget {
  const _InputSettingsTile({
    required this.icon,
    required this.title,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
  });

  final IconData icon;
  final String title;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;

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
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              cursorColor: AppColors.accent(context),
              decoration: InputDecoration(
                labelText: title,
                border: InputBorder.none,
                labelStyle: AppTextStyles.label(context),
              ),
            ),
          ),
        ],
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

BoxDecoration _settingsBoxDecoration(BuildContext context) {
  return BoxDecoration(
    color: AppColors.card(context),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border(context)),
  );
}
