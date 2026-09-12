import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/features/order/presentation/helpers/customer_contact_launcher.dart';

void main() {
  test('builds WhatsApp and phone contact links from customer phone', () {
    final links = customerContactLinks('+243 999 000 111');

    expect(links, isNotNull);
    expect(links!.whatsapp.toString(), 'https://wa.me/243999000111');
    expect(links.phone.toString(), 'tel:+243999000111');
  });

  test('rejects empty contact phone', () {
    expect(customerContactLinks(''), isNull);
  });
}
