import 'package:flutter/material.dart';
import 'package:vendza/core/config/google_auth_config.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/constants/strings.dart';
import 'package:vendza/features/auth/presantation/pages/login_page.dart';
import 'package:vendza/features/auth/presantation/pages/register_page.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_layout.dart';
import 'package:vendza/features/auth/presantation/widgets/google_sign_in_button.dart';
import 'package:vendza/features/auth/presantation/widgets/header.dart';
import 'package:vendza/navigation/main_page.dart';
import 'package:vendza/shared/widgets/bouton/button.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class OnbordingPage extends StatelessWidget {
  const OnbordingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      compactHeaderStyle: AuthCompactHeaderStyle.centered,
      child: _OnboardingContent(),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = AppBreakpoints.authLayoutMode(constraints.maxWidth);
        final actions = _OnboardingActions(mode: mode);

        return switch (mode) {
          AuthLayoutMode.compact => ResponsiveContent(
            maxWidth: 520,
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                child: actions,
              ),
            ),
          ),
          AuthLayoutMode.medium => _OnboardingCard(mode: mode, child: actions),
          AuthLayoutMode.expanded => actions,
        };
      },
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.mode, required this.child});

  final AuthLayoutMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.32 : 0.14,
            ),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeaderWidget(mode: mode),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _OnboardingActions extends StatelessWidget {
  const _OnboardingActions({required this.mode});

  final AuthLayoutMode mode;

  @override
  Widget build(BuildContext context) {
    final isCompact = mode == AuthLayoutMode.compact;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 0),
      decoration: isCompact
          ? BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: AppBouton(
              text: AppStrings.login,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              enabled: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isCompact
                    ? Colors.white
                    : AppColors.accent(context),
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: BorderSide(
                  color: isCompact
                      ? Colors.white.withValues(alpha: 0.55)
                      : AppColors.border(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Créer un compte',
                style: TextStyle(
                  color: isCompact ? Colors.white : AppColors.accent(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (GoogleAuthConfig.isConfigured) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isCompact
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppColors.border(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: TextStyle(
                      color: isCompact
                          ? Colors.white.withValues(alpha: 0.78)
                          : AppColors.textSecondary(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isCompact
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppColors.border(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GoogleSignInButton(
              foregroundColor: isCompact ? Colors.white : null,
              borderColor: isCompact
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppColors.border(context),
              onAuthenticated: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainPage()),
                  (route) => false,
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Achetez, vendez et découvrez des boutiques en toute simplicité.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isCompact
                  ? AppColors.textwhite.withValues(alpha: 0.78)
                  : AppColors.textSecondary(context),
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
