import 'package:flutter_test/flutter_test.dart';
import 'package:vendza/core/services/share/whatsapp_product_inquiry.dart';

void main() {
  test('ends the greeting with a colon and a continue-writing mark', () {
    final message = WhatsappProductInquiry.message(
      productId: '42',
      productName: 'Robe wax',
      priceLabel: '25 000 CDF',
    );

    expect(message, contains('Robe wax — 25 000 CDF :'));
    expect(message, contains(WhatsappProductInquiry.continueWritingMark));
    expect(
      message.indexOf(' :'),
      lessThan(message.indexOf(WhatsappProductInquiry.continueWritingMark)),
    );
    expect(
      message.indexOf(WhatsappProductInquiry.continueWritingMark),
      lessThan(message.indexOf('https://app.vendza.online/p/42')),
    );
  });

  test('can place a public image URL between the prompt and the product link', () {
    final message = WhatsappProductInquiry.message(
      productId: '42',
      productName: 'Robe wax',
      imageUrl: 'https://cdn.vendza.app/robe.jpg',
      includeImageUrl: true,
    );

    final promptAt = message.indexOf(WhatsappProductInquiry.continueWritingMark);
    final photoAt = message.indexOf('https://cdn.vendza.app/robe.jpg');
    final productAt = message.indexOf('https://app.vendza.online/p/42');

    expect(photoAt, greaterThan(promptAt));
    expect(productAt, greaterThan(photoAt));
  });

  test('omits local image URLs from the WhatsApp message', () {
    final message = WhatsappProductInquiry.message(
      productId: '7',
      productName: 'Sac',
      imageUrl: 'http://localhost:9000/sac.png',
      includeImageUrl: true,
    );

    expect(message, isNot(contains('localhost')));
    expect(message, contains('https://app.vendza.online/p/7'));
  });

  test('does not embed the image URL when the photo is attached separately', () {
    final message = WhatsappProductInquiry.message(
      productId: '42',
      productName: 'Robe wax',
      imageUrl: 'https://cdn.vendza.app/robe.jpg',
    );

    expect(message, isNot(contains('cdn.vendza.app')));
  });

  test('adds the product text to an existing wa.me link', () {
    final uri = WhatsappProductInquiry.conversationUri(
      'https://wa.me/243800000000',
      'Bonjour\nhttps://vendza.app/p/9',
    );

    expect(uri, isNotNull);
    expect(uri!.host, 'wa.me');
    expect(uri.path, '/243800000000');
    expect(uri.queryParameters['text'], 'Bonjour\nhttps://vendza.app/p/9');
  });

  test('reads the phone digits from wa.me and api.whatsapp.com links', () {
    expect(
      WhatsappProductInquiry.phoneDigits('https://wa.me/243800000000'),
      '243800000000',
    );
    expect(
      WhatsappProductInquiry.phoneDigits(
        'https://api.whatsapp.com/send?phone=+243800000000',
      ),
      '243800000000',
    );
  });
}
