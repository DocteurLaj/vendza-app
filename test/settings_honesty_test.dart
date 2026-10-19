import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/constants/site_links.dart';
import 'package:vendza/features/settings/presentation/pages/settings_detail_pages.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: page));
  }

  testWidgets('privacy page no longer shows a password form that cannot work', (
    tester,
  ) async {
    await pumpPage(tester, const PrivacySettingsPage());

    // #107: no editable email / password fields, no fake "Enregistrer".
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Mot de passe actuel'), findsNothing);
    expect(find.text('Enregistrer'), findsNothing);
    expect(find.textContaining('pas encore disponible'), findsNothing);

    // The real, working flow is offered instead.
    expect(
      find.byKey(const ValueKey('privacy-reset-password')),
      findsOneWidget,
    );
    expect(find.text('Changer mon mot de passe'), findsOneWidget);
  });

  testWidgets('change password entry opens the reset-by-email dialog', (
    tester,
  ) async {
    await pumpPage(tester, const PrivacySettingsPage());
    await tester.tap(find.byKey(const ValueKey('privacy-reset-password')));
    await tester.pumpAndSettle();
    expect(
      find.byType(Dialog).evaluate().isNotEmpty ||
          find.byType(AlertDialog).evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('feedback page never claims a fake successful send', (
    tester,
  ) async {
    await pumpPage(tester, const FeedbackSettingsPage());
    expect(find.text('Envoyer par email'), findsOneWidget);
    expect(find.text('Soumettre'), findsNothing);
    expect(find.text('Merci pour votre feedback'), findsNothing);
  });

  test('feedback mailto carries subject and body to the support address', () {
    final uri = SiteLinks.mailtoSupport(
      subject: 'Feedback Vendza',
      body: 'Très bien & rapide',
    );
    expect(uri.scheme, 'mailto');
    expect(uri.path, SiteLinks.supportEmail);
    expect(uri.query, contains('subject=Feedback%20Vendza'));
    expect(uri.query, contains('body=Tr%C3%A8s%20bien%20%26%20rapide'));
  });

  test('default support mailto is unchanged', () {
    expect(
      SiteLinks.mailtoSupport().query,
      'subject=${Uri.encodeComponent('Support Vendza')}',
    );
  });
}
