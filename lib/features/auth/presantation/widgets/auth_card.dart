import 'package:flutter/material.dart';
import 'package:vendza/core/constants/breakpoints.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/features/auth/presantation/widgets/header.dart';
import 'package:vendza/shared/widgets/layout/responsive_content.dart';

class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.heightFactor = 0.58,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = AppBreakpoints.authLayoutMode(constraints.maxWidth);

        return switch (mode) {
          AuthLayoutMode.compact => _CompactAuthCard(
            title: title,
            subtitle: subtitle,
            heightFactor: heightFactor,
            maxHeight: constraints.maxHeight,
            children: children,
          ),
          AuthLayoutMode.medium => _MediumAuthCard(
            title: title,
            subtitle: subtitle,
            children: children,
          ),
          AuthLayoutMode.expanded => _ExpandedAuthCard(
            title: title,
            subtitle: subtitle,
            children: children,
          ),
        };
      },
    );
  }
}

class _CompactAuthCard extends StatelessWidget {
  const _CompactAuthCard({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.heightFactor,
    required this.maxHeight,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final double heightFactor;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isShortScreen = screenHeight < 700;

    final boundedMaxHeight = maxHeight.isFinite
        ? maxHeight
        : screenHeight - mediaQuery.viewInsets.bottom;

    final targetHeight = (screenHeight * heightFactor)
        .clamp(280.0, boundedMaxHeight * 0.94)
        .toDouble();

    return ResponsiveContent(
      maxWidth: 520,
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: targetHeight,
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(22, isShortScreen ? 8 : 12, 22, 18),
        decoration: _cardDecoration(
          context,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          showTopBorder: true,
          showShadow: true,
        ),
        child: SafeArea(
          top: false,
          child: _AuthCardBody(
            title: title,
            subtitle: subtitle,
            showHandle: true,
            expandScroll: true,
            compact: true,
            isShortScreen: isShortScreen,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _MediumAuthCard extends StatelessWidget {
  const _MediumAuthCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset + 8 : 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: _cardDecoration(
          context,
          borderRadius: BorderRadius.circular(28),
          showTopBorder: false,
          showShadow: true,
        ),
        child: _AuthCardBody(
          title: title,
          subtitle: subtitle,
          showHandle: false,
          showBrandingHeader: true,
          brandingMode: AuthLayoutMode.medium,
          children: children,
        ),
      ),
    );
  }
}

class _ExpandedAuthCard extends StatelessWidget {
  const _ExpandedAuthCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _AuthCardBody(
      title: title,
      subtitle: subtitle,
      showHandle: false,
      children: children,
    );
  }
}

BoxDecoration _cardDecoration(
  BuildContext context, {
  required BorderRadius borderRadius,
  required bool showTopBorder,
  required bool showShadow,
}) {
  return BoxDecoration(
    color: AppColors.card(context),
    borderRadius: borderRadius,
    border: showTopBorder
        ? Border(top: BorderSide(color: AppColors.border(context)))
        : Border.all(color: AppColors.border(context)),
    boxShadow: showShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark(context) ? 0.32 : 0.14,
              ),
              blurRadius: 28,
              offset: const Offset(0, -10),
            ),
          ]
        : null,
  );
}

class _AuthCardBody extends StatelessWidget {
  const _AuthCardBody({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.showHandle,
    this.showBrandingHeader = false,
    this.brandingMode = AuthLayoutMode.compact,
    this.expandScroll = false,
    this.compact = false,
    this.isShortScreen = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showHandle;
  final bool showBrandingHeader;
  final AuthLayoutMode brandingMode;
  final bool expandScroll;
  final bool compact;
  final bool isShortScreen;

  @override
  Widget build(BuildContext context) {
    final titleSize = isShortScreen ? 20.0 : 22.0;
    final sectionGap = isShortScreen ? 18.0 : 26.0;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBrandingHeader) ...[
          HeaderWidget(mode: brandingMode),
          SizedBox(height: isShortScreen ? 20 : 28),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: isShortScreen ? 4 : 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary(context),
            fontSize: isShortScreen ? 12.5 : 13,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: sectionGap),
        ...children,
      ],
    );

    final scrollView = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: compact
          ? const BouncingScrollPhysics()
          : const ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: compact ? 4 : 0),
      child: content,
    );

    return Column(
      children: [
        if (showHandle)
          Container(
            width: 42,
            height: 5,
            margin: EdgeInsets.only(bottom: isShortScreen ? 12 : 18),
            decoration: BoxDecoration(
              color: AppColors.accent(context).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        if (expandScroll) Expanded(child: scrollView) else scrollView,
      ],
    );
  }
}
