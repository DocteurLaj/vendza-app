import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vendza/core/connectivity/network_status.dart';
import 'package:vendza/core/monitoring/error_reporter.dart';
import 'package:vendza/core/services/api_config.dart';
import 'package:vendza/core/services/deep_link/deep_link_service.dart';
import 'package:vendza/core/theme/app_theme.dart';
import 'package:vendza/core/theme/theme_controller.dart';
import 'package:vendza/features/animation/animation_screen.dart';
import 'package:vendza/navigation/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.validateForCurrentBuild();
  await ErrorReporter.ensureInitialized();
  // Do not block the first frame on platform plugins. The splash screen restores
  // tokens/profile with a short timeout, while connectivity starts in the background.
  unawaited(NetworkStatus.start());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    DeepLinkService.instance.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.markAuthNavigationReady();
    });
  }

  @override
  void dispose() {
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeController,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Vendza',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: SplashScreen(),
        );
      },
    );
  }
}
