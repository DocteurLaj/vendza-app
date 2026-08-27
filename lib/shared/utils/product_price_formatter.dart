String formatProductPriceLabel(String price, {bool currencyFirst = false}) {
  final parsed = parseProductPriceParts(price);
  if (parsed.amount.isEmpty) return "";

  if (currencyFirst) {
    return "${parsed.currency} ${parsed.amount}";
  }
  return "${parsed.amount} ${parsed.currency}";
}

ProductPriceParts parseProductPriceParts(String price) {
  final trimmedPrice = price.trim();
  if (trimmedPrice.isEmpty) {
    return const ProductPriceParts(amount: "", currency: "CDF");
  }

  final currency = _detectCurrency(trimmedPrice);
  final numeric = _extractNumericValue(trimmedPrice);
  if (numeric == null) {
    return ProductPriceParts(amount: trimmedPrice, currency: currency);
  }

  return ProductPriceParts(amount: _formatAmount(numeric), currency: currency);
}

ProductPriceInputValue parseProductPriceInputValue(String price) {
  final parts = parseProductPriceParts(price);
  final currency = parts.currency == "FC" ? "CDF" : parts.currency;
  // Edit fields use whole-number digit grouping only.
  final amountDigits = parts.amount.replaceAll(RegExp(r"[^\d]"), "");
  return ProductPriceInputValue(
    amount: _formatThousands(amountDigits),
    currency: currency,
  );
}

class ProductPriceParts {
  const ProductPriceParts({required this.amount, required this.currency});

  final String amount;
  final String currency;
}

class ProductPriceInputValue {
  const ProductPriceInputValue({required this.amount, required this.currency});

  final String amount;
  final String currency;
}

String _detectCurrency(String price) {
  final lower = price.toLowerCase();
  if (lower.contains("usd") || price.contains(r"$")) return "USD";
  if (lower.contains("cdf")) return "CDF";
  if (RegExp(r"\bfc\b").hasMatch(lower) || lower.contains("franc")) {
    return "FC";
  }

  final parts = price.trim().split(RegExp(r"\s+"));
  if (parts.isNotEmpty) {
    final last = parts.last.toUpperCase();
    if (last == "CDF" || last == "USD" || last == "FC") return last;
  }

  return "CDF";
}

double? _extractNumericValue(String price) {
  final sanitized = price
      .replaceAll(RegExp(r"[^\d.,\s]"), " ")
      .replaceAll(",", ".")
      .trim();
  if (sanitized.isEmpty) return null;

  final match = RegExp(r"(\d+(?:\.\d+)?)").firstMatch(sanitized);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return _formatThousands(value.round().toString());
  }

  final whole = value.truncate();
  final cents = ((value - whole).abs() * 100).round().clamp(0, 99);
  return "${_formatThousands(whole.toString())}.${cents.toString().padLeft(2, '0')}";
}

String _formatThousands(String digits) {
  final clean = digits.replaceAll(RegExp(r"[^\d]"), "");
  if (clean.isEmpty) return "";

  final buffer = StringBuffer();
  for (int index = 0; index < clean.length; index++) {
    final int remaining = clean.length - index;
    buffer.write(clean[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(" ");
    }
  }

  return buffer.toString();
}
