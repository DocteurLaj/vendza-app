import 'package:url_launcher/url_launcher.dart';

class SiteLinks {
  static const String host = 'vendza.online';
  static const String origin = 'https://$host';

  static const String about = '$origin/a-propos';
  static const String learnMore = '$origin/en-savoir-plus';
  static const String download = '$origin/telecharger';
  static const String contact = '$origin/contact';
  static const String privacy = '$origin/confidentialite';
  static const String terms = '$origin/conditions';
  static const String deleteAccount = '$origin/suppression-compte';
  static const String subscription = '$origin/en-savoir-plus#abonnement';

  static const String supportEmail = 'support@support.vendza.online';
  static const String supportWhatsApp = String.fromEnvironment(
    'VENDZA_SUPPORT_WHATSAPP',
  );

  static bool get hasSupportWhatsApp => whatsappUri != null;

  static Uri mailtoSupport({String subject = 'Support Vendza'}) {
    return Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
  }

  static Uri? get whatsappUri {
    final digits = supportWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return Uri.parse('https://wa.me/$digits');
  }

  static Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openUri(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
