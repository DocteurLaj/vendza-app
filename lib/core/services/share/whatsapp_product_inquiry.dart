import 'package:vendza/core/services/share/share_link_builder.dart';

class WhatsappProductInquiry {
  const WhatsappProductInquiry._();

  static const continueWritingMark = '✍️ …';

  static String message({
    required String productId,
    required String productName,
    String priceLabel = '',
    String imageUrl = '',
    bool includeImageUrl = false,
  }) {
    final name = productName.trim().isEmpty ? 'ce produit' : productName.trim();
    final buffer = StringBuffer('Bonjour, je suis intéressé par $name');
    final price = priceLabel.trim();
    if (price.isNotEmpty) {
      buffer.write(' — $price');
    }
    buffer
      ..write(' :')
      ..writeln()
      ..writeln()
      ..write(continueWritingMark);

    if (includeImageUrl) {
      final photo = publicHttpUrl(imageUrl);
      if (photo != null) {
        buffer
          ..writeln()
          ..writeln()
          ..write(photo);
      }
    }

    buffer
      ..writeln()
      ..writeln()
      ..write(ShareLinkBuilder.productUrl(productId));

    return buffer.toString();
  }

  static Uri? conversationUri(String whatsappLink, String text) {
    final trimmed = whatsappLink.trim();
    if (trimmed.isEmpty || text.trim().isEmpty) return null;

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return null;
    }

    return parsed.replace(
      queryParameters: {...parsed.queryParameters, 'text': text},
    );
  }

  static String? phoneDigits(String whatsappLink) {
    final parsed = Uri.tryParse(whatsappLink.trim());
    if (parsed == null) return null;

    final fromQuery =
        parsed.queryParameters['phone']?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (fromQuery.isNotEmpty) return fromQuery;

    final fromPath = parsed.path.replaceAll(RegExp(r'\D'), '');
    return fromPath.isEmpty ? null : fromPath;
  }

  static String? publicHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host == 'minio' ||
        host == 'host.docker.internal') {
      return null;
    }
    return uri.toString();
  }
}
