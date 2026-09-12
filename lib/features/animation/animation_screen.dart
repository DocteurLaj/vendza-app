import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/catalog/catalog_repository.dart';
import 'package:vendza/core/constants/colors.dart';
import 'package:vendza/core/services/api_token_store.dart';
import 'package:vendza/core/session/current_user_store.dart';
import 'package:vendza/features/auth/data/services/auth_session_service.dart';
import 'package:vendza/features/auth/presantation/pages/onbording_page.dart';
import 'package:vendza/navigation/main_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _appVersion = "Version 1.0.0";

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.92,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.12,
          end: 0.98,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 18,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.98,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 14,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 30),
    ]).animate(_controller);

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.35, curve: Curves.easeOut),
    );

    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          unawaited(_finishStartup());
        }
      })
      ..forward();
  }

  Future<void> _finishStartup() async {
    var sessionRestored = false;
    try {
      await apiTokenStore.restore().timeout(const Duration(seconds: 2));
      await catalogRepository.restoreCachedCatalog().timeout(
        const Duration(milliseconds: 700),
        onTimeout: () => false,
      );
      sessionRestored = await authSessionService
          .restoreSession(syncCatalog: false)
          .timeout(const Duration(seconds: 4), onTimeout: () => false);
    } on Object {
      sessionRestored = false;
    }

    if (!mounted) return;
    _navigate(sessionRestored);
    _warmCatalogAfterNavigation(sessionRestored);
  }

  void _navigate(bool sessionRestored) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            sessionRestored ? const MainPage() : const OnbordingPage(),
        transitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _warmCatalogAfterNavigation(bool sessionRestored) {
    final userId = currentUserStore.value.userId ?? 0;
    unawaited(
      (sessionRestored && userId > 0
              ? bootstrapSessionCatalog(userId: userId)
              : bootstrapCatalog())
          .timeout(const Duration(seconds: 20), onTimeout: () {})
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: Image.asset(
                    'assets/icons/icon.png',
                    width: 175,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Text(
                _appVersion,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
