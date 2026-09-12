import 'package:url_launcher/url_launcher.dart';
import 'package:vendza/shared/utils/phone_number.dart';

class CustomerContactLinks {
  const CustomerContactLinks({required this.whatsapp, required this.phone});

  final Uri whatsapp;
  final Uri phone;
}

CustomerContactLinks? customerContactLinks(String rawPhone) {
  final parsed = parsePhoneNumber(rawPhone);
  if (parsed.e164.isEmpty) return null;
  final digits = digitsOnly(parsed.e164);
  return CustomerContactLinks(
    whatsapp: Uri.parse('https://wa.me/$digits'),
    phone: Uri.parse('tel:${parsed.e164}'),
  );
}

Future<bool> openCustomerContact(String rawPhone) async {
  final links = customerContactLinks(rawPhone);
  if (links == null) return false;
  final openedWhatsapp = await launchUrl(
    links.whatsapp,
    mode: LaunchMode.externalApplication,
  );
  if (openedWhatsapp) return true;
  return launchUrl(links.phone, mode: LaunchMode.externalApplication);
}
