import 'package:flutter/material.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/site_links.dart';
import 'package:vendza/core/services/api_exception.dart';
import 'package:vendza/core/theme/app_text_styles.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/presantation/pages/onbording_page.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, this.sessionService, this.isGoogleOnly});

  final AuthSessionService? sessionService;
  final bool? isGoogleOnly;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _confirmationController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  bool get _isGoogleOnly => widget.isGoogleOnly ?? false;

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final confirmation = _confirmationController.text.trim();
    if (confirmation != 'SUPPRIMER') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tapez SUPPRIMER pour confirmer la suppression.'),
        ),
      );
      return;
    }
    if (!_isGoogleOnly && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mot de passe requis.')));
      return;
    }

    setState(() => _loading = true);
    try {
      await (widget.sessionService ?? authSessionService).deleteAccount(
        password: _isGoogleOnly ? null : _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnbordingPage()),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suppression impossible pour le moment.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.appBackground(context),
        foregroundColor: AppColors.textPrimary(context),
        elevation: 0,
        title: Text(
          'Supprimer mon compte',
          style: AppTextStyles.pageTitle(context),
        ),
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
                  Text(
                    'Cette action est definitive.',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vos donnees personnelles seront anonymisees. '
                    'Les commandes sont conservees pour la comptabilite. '
                    'Vos favoris, notifications et sessions seront supprimes. '
                    'Vos boutiques et produits seront retires de la vente.',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => SiteLinks.open(SiteLinks.deleteAccount),
                    child: const Text('Lire la page suppression de compte'),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _confirmationController,
                    decoration: const InputDecoration(
                      labelText: 'Tapez SUPPRIMER',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (!_isGoogleOnly) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const ValueKey('delete-account-confirm'),
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _loading
                            ? 'Suppression...'
                            : 'Supprimer definitivement',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
