import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/constants/site_links.dart';

void main() {
  test('maps each site page to the matching vendza.online URL', () {
    expect(SiteLinks.about, 'https://vendza.online/a-propos');
    expect(SiteLinks.learnMore, 'https://vendza.online/en-savoir-plus');
    expect(SiteLinks.terms, 'https://vendza.online/conditions');
    expect(SiteLinks.privacy, 'https://vendza.online/confidentialite');
    expect(SiteLinks.contact, 'https://vendza.online/contact');
    expect(SiteLinks.deleteAccount, 'https://vendza.online/suppression-compte');
    expect(
      SiteLinks.subscription,
      'https://vendza.online/en-savoir-plus#abonnement',
    );
  });

  test('builds a support mailto and hides WhatsApp without a number', () {
    expect(SiteLinks.supportEmail, 'support@support.vendza.online');
    expect(SiteLinks.mailtoSupport().scheme, 'mailto');
    expect(SiteLinks.mailtoSupport().path, SiteLinks.supportEmail);
    expect(SiteLinks.hasSupportWhatsApp, isFalse);
    expect(SiteLinks.whatsappUri, isNull);
  });
}
