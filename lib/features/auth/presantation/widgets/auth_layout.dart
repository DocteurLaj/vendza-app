import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/auth/presantation/widgets/auth_header_space.dart';
import 'package:vendza/features/auth/presantation/widgets/backgroud_img.dart';
import 'package:vendza/features/auth/presantation/widgets/header.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

enum AuthCompactHeaderStyle { topSpace, centered, none }

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    this.compactHeaderHeightFactor = 0.42,
    this.compactHeaderTopPadding = 26,
    this.compactHeaderStyle = AuthCompactHeaderStyle.topSpace,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final double compactHeaderHeightFactor;
  final double compactHeaderTopPadding;
  final AuthCompactHeaderStyle compactHeaderStyle;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = AppBreakpoints.authLayoutMode(constraints.maxWidth);

        return switch (mode) {
          AuthLayoutMode.compact => _CompactAuthLayout(
            compactHeaderHeightFactor: compactHeaderHeightFactor,
            compactHeaderTopPadding: compactHeaderTopPadding,
            compactHeaderStyle: compactHeaderStyle,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            child: child,
          ),
          AuthLayoutMode.medium => _MediumAuthLayout(child: child),
          AuthLayoutMode.expanded => _ExpandedAuthLayout(child: child),
        };
      },
    );
  }
}

class _CompactAuthLayout extends StatelessWidget {
  const _CompactAuthLayout({
    required this.child,
    required this.compactHeaderHeightFactor,
    required this.compactHeaderTopPadding,
    required this.compactHeaderStyle,
    required this.resizeToAvoidBottomInset,
  });

  final Widget child;
  final double compactHeaderHeightFactor;
  final double compactHeaderTopPadding;
  final AuthCompactHeaderStyle compactHeaderStyle;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final keyboardIsOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackgroudImg(),
          if (!keyboardIsOpen &&
              compactHeaderStyle == AuthCompactHeaderStyle.topSpace)
            AuthHeaderSpace(
              heightFactor: compactHeaderHeightFactor,
              topPadding: compactHeaderTopPadding,
            ),
          if (!keyboardIsOpen &&
              compactHeaderStyle == AuthCompactHeaderStyle.centered)
            const Center(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 130),
                  child: HeaderWidget(mode: AuthLayoutMode.compact),
                ),
              ),
            ),
          Positioned(left: 0, right: 0, bottom: 0, child: child),
        ],
      ),
    );
  }
}

class _MediumAuthLayout extends StatelessWidget {
  const _MediumAuthLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BackgroudImg(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ResponsiveContent(maxWidth: 520, child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedAuthLayout extends StatelessWidget {
  const _ExpandedAuthLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Expanded(flex: 45, child: AuthBrandingPanel()),
          Expanded(flex: 55, child: AuthFormPanel(child: child)),
        ],
      ),
    );
  }
}

class AuthBrandingPanel extends StatelessWidget {
  const AuthBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        BackgroudImg(),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: HeaderWidget(mode: AuthLayoutMode.expanded),
          ),
        ),
      ],
    );
  }
}

class AuthFormPanel extends StatelessWidget {
  const AuthFormPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.card(context),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ResponsiveContent(maxWidth: 440, child: child),
          ),
        ),
      ),
    );
  }
}
