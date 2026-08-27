import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vendza/core/services/share/share_image_resolver.dart';
import 'package:vendza/core/services/share/share_link_builder.dart';
import 'package:vendza/features/home/data/models/store_model.dart';
import 'package:vendza/shared/models/product_model.dart';
import 'package:vendza/shared/utils/product_price_formatter.dart';

class AppShareService {
  const AppShareService._();

  static Future<void> shareProduct(
    BuildContext context,
    ProductModel product,
  ) async {
    final priceLabel = formatProductPriceLabel(product.price);
    final message =
        'Découvre ${product.name} sur Vendza — $priceLabel\n'
        '${ShareLinkBuilder.productUrl(product.id)}';

    final imageFile = await ShareImageResolver.resolve(product.imageurl);
    if (!context.mounted) return;
    await _share(context, message, imageFile: imageFile);
  }

  static Future<void> shareStore(BuildContext context, StoreModel store) async {
    final description = store.getDescription().trim();
    final buffer = StringBuffer(
      'Découvre la boutique ${store.name} sur Vendza',
    );

    if (description.isNotEmpty &&
        description != 'Aucune description disponible') {
      buffer.writeln();
      buffer.write(description);
    }

    buffer.writeln();
    buffer.write(ShareLinkBuilder.storeUrl(store.id));

    final imageFile = await ShareImageResolver.resolve(store.image);
    if (!context.mounted) return;
    await _share(context, buffer.toString(), imageFile: imageFile);
  }

  static Future<void> _share(
    BuildContext context,
    String message, {
    XFile? imageFile,
  }) async {
    final trimmed = message.trim();
    final shareOrigin = _shareOrigin(context);

    final ShareResult result;
    if (imageFile != null) {
      result = await Share.shareXFiles(
        [imageFile],
        text: trimmed,
        sharePositionOrigin: shareOrigin,
      );
    } else {
      result = await Share.share(trimmed, sharePositionOrigin: shareOrigin);
    }

    if (!context.mounted) return;

    if (result.status == ShareResultStatus.unavailable) {
      await Clipboard.setData(ClipboardData(text: trimmed));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien copié dans le presse-papier')),
      );
    }
  }

  static Rect? _shareOrigin(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }
}
