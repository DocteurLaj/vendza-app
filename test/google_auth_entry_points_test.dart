import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/config/google_auth_config.dart';
import 'package:vendza/features/auth/presantation/pages/login_page.dart';
import 'package:vendza/features/auth/presantation/pages/onbording_page.dart';
import 'package:vendza/features/auth/presantation/pages/register_page.dart';

void main() {
  tearDown(() {
    GoogleAuthConfig.debugIsConfiguredOverride = null;
  });

  testWidgets('Google Sign-In is hidden when OAuth is not configured', (
    tester,
  ) async {
    GoogleAuthConfig.debugIsConfiguredOverride = false;
    await tester.pumpWidget(const MaterialApp(home: OnbordingPage()));
    expect(find.byKey(const ValueKey('google-sign-in-button')), findsNothing);
  });

  testWidgets('onboarding exposes Google Sign-In when configured', (
    tester,
  ) async {
    GoogleAuthConfig.debugIsConfiguredOverride = true;
    await tester.pumpWidget(const MaterialApp(home: OnbordingPage()));
    expect(find.byKey(const ValueKey('google-sign-in-button')), findsOneWidget);
  });

  testWidgets('login exposes Google Sign-In when configured', (tester) async {
    GoogleAuthConfig.debugIsConfiguredOverride = true;
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.byKey(const ValueKey('google-sign-in-button')), findsOneWidget);
  });

  testWidgets('registration requires terms before Google Sign-In', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    GoogleAuthConfig.debugIsConfiguredOverride = true;
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
    final googleButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('google-sign-in-button')),
    );
    expect(googleButton.onPressed, isNull);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final enabledButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('google-sign-in-button')),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
