import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendza/core/services/share/share_image_resolver.dart';
import 'package:vendza/core/services/share/whatsapp_product_inquiry.dart';

class WhatsappSellerChat {
  const WhatsappSellerChat._();

  static const _channel = MethodChannel('app.vendza.marketplace/whatsapp');

  static Future<bool> open({
    required String whatsappLink,
    required String productId,
    required String productName,
    String priceLabel = '',
    String imageUrl = '',
  }) async {
    final phone = WhatsappProductInquiry.phoneDigits(whatsappLink);
    final imageFile = kIsWeb || imageUrl.trim().isEmpty
        ? null
        : await ShareImageResolver.resolve(imageUrl);

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        phone != null) {
      final caption = WhatsappProductInquiry.message(
        productId: productId,
        productName: productName,
        priceLabel: priceLabel,
      );
      try {
        final opened = await _channel.invokeMethod<bool>('shareProduct', {
          'phone': phone,
          'text': caption,
          'filePath': imageFile?.path,
        });
        if (opened == true) return true;
      } on PlatformException {
        // Fall back to wa.me below.
      }
    }

    final text = WhatsappProductInquiry.message(
      productId: productId,
      productName: productName,
      priceLabel: priceLabel,
      imageUrl: imageUrl,
      includeImageUrl: true,
    );
    final uri = WhatsappProductInquiry.conversationUri(whatsappLink, text);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
