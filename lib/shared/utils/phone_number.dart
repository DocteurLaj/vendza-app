class PhoneCountry {
  const PhoneCountry({
    required this.iso,
    required this.name,
    required this.dialCode,
    required this.nationalLength,
    this.flag = '',
  });

  final String iso;
  final String name;
  final String dialCode;
  final int nationalLength;
  final String flag;
}

const List<PhoneCountry> kPhoneCountries = [
  PhoneCountry(iso: 'CD', name: 'RD Congo', dialCode: '243', nationalLength: 9, flag: '🇨🇩'),
  PhoneCountry(iso: 'CG', name: 'Congo', dialCode: '242', nationalLength: 9, flag: '🇨🇬'),
  PhoneCountry(iso: 'RW', name: 'Rwanda', dialCode: '250', nationalLength: 9, flag: '🇷🇼'),
  PhoneCountry(iso: 'BI', name: 'Burundi', dialCode: '257', nationalLength: 8, flag: '🇧🇮'),
  PhoneCountry(iso: 'UG', name: 'Ouganda', dialCode: '256', nationalLength: 9, flag: '🇺🇬'),
  PhoneCountry(iso: 'KE', name: 'Kenya', dialCode: '254', nationalLength: 9, flag: '🇰🇪'),
  PhoneCountry(iso: 'TZ', name: 'Tanzanie', dialCode: '255', nationalLength: 9, flag: '🇹🇿'),
  PhoneCountry(iso: 'AO', name: 'Angola', dialCode: '244', nationalLength: 9, flag: '🇦🇴'),
  PhoneCountry(iso: 'ZA', name: 'Afrique du Sud', dialCode: '27', nationalLength: 9, flag: '🇿🇦'),
  PhoneCountry(iso: 'FR', name: 'France', dialCode: '33', nationalLength: 9, flag: '🇫🇷'),
  PhoneCountry(iso: 'BE', name: 'Belgique', dialCode: '32', nationalLength: 9, flag: '🇧🇪'),
  PhoneCountry(iso: 'CA', name: 'Canada', dialCode: '1', nationalLength: 10, flag: '🇨🇦'),
  PhoneCountry(iso: 'US', name: 'États-Unis', dialCode: '1', nationalLength: 10, flag: '🇺🇸'),
];

PhoneCountry phoneCountryByIso(String iso) {
  return kPhoneCountries.firstWhere(
    (country) => country.iso == iso,
    orElse: () => kPhoneCountries.first,
  );
}

class ParsedPhoneNumber {
  const ParsedPhoneNumber({
    required this.country,
    required this.national,
  });

  final PhoneCountry country;
  final String national;

  String get e164 {
    if (national.isEmpty) return '';
    return '+${country.dialCode}$national';
  }

  bool get isValid => national.length == country.nationalLength;
}

String digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

ParsedPhoneNumber parsePhoneNumber(String raw, {String defaultIso = 'CD'}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return ParsedPhoneNumber(country: phoneCountryByIso(defaultIso), national: '');
  }

  var digits = digitsOnly(trimmed);
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }

  final matches = kPhoneCountries.where((country) => digits.startsWith(country.dialCode)).toList()
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  if (matches.isNotEmpty) {
    final country = matches.first;
    var national = digits.substring(country.dialCode.length);
    if (national.length > country.nationalLength) {
      national = national.substring(0, country.nationalLength);
    }
    return ParsedPhoneNumber(country: country, national: national);
  }

  final country = phoneCountryByIso(defaultIso);
  var national = digits;
  if (national.startsWith('0')) {
    national = national.substring(1);
  }
  if (national.length > country.nationalLength) {
    national = national.substring(0, country.nationalLength);
  }
  return ParsedPhoneNumber(country: country, national: national);
}

String whatsappUrlFromPhone(String raw) {
  final parsed = parsePhoneNumber(raw);
  if (parsed.e164.isEmpty) return '';
  return 'https://wa.me/${digitsOnly(parsed.e164)}';
}
