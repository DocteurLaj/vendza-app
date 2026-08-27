import 'package:flutter/material.dart';
import 'package:vendza/shared/utils/product_price_formatter.dart';

/// Displays a product price with currency, preferring suffix (`1 800 CDF`).
/// On narrow widths, switches to prefix (`CDF 1 800`) so the devise stays visible.
class ProductPriceText extends StatelessWidget {
  const ProductPriceText(
    this.price, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.softWrap = false,
    this.overflow = TextOverflow.ellipsis,
    this.currencyFirstBelowWidth = 96,
  });

  final String price;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool softWrap;
  final TextOverflow overflow;
  final double currencyFirstBelowWidth;

  @override
  Widget build(BuildContext context) {
    final suffixLabel = formatProductPriceLabel(price);
    if (suffixLabel.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final usePrefix =
            maxWidth.isFinite && maxWidth < currencyFirstBelowWidth;

        final label = formatProductPriceLabel(price, currencyFirst: usePrefix);

        // If still too wide with suffix, force currency-first for visibility.
        if (!usePrefix && maxWidth.isFinite && maxWidth > 0) {
          final painter = TextPainter(
            text: TextSpan(text: suffixLabel, style: style),
            maxLines: maxLines,
            textDirection: TextDirection.ltr,
            ellipsis: '…',
          )..layout(maxWidth: maxWidth);

          if (painter.didExceedMaxLines || painter.width > maxWidth) {
            return Text(
              formatProductPriceLabel(price, currencyFirst: true),
              style: style,
              textAlign: textAlign,
              maxLines: maxLines,
              softWrap: softWrap,
              overflow: overflow,
            );
          }
        }

        return Text(
          label,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          softWrap: softWrap,
          overflow: overflow,
        );
      },
    );
  }
}
