class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.nationalLength,
  });

  final String name;
  final String isoCode;
  final String dialCode;
  final int nationalLength;

  String get flagEmoji {
    final code = isoCode.toUpperCase();
    if (code.length != 2) return '🌍';
    return String.fromCharCodes([
      0x1F1E6 + code.codeUnitAt(0) - 65,
      0x1F1E6 + code.codeUnitAt(1) - 65,
    ]);
  }

  String formatE164(String nationalDigits) => '$dialCode$nationalDigits';
}

/// Common dial codes for customer sign-in (India first).
abstract final class CountryDialCodes {
  static const india = CountryDialCode(
    name: 'India',
    isoCode: 'IN',
    dialCode: '+91',
    nationalLength: 10,
  );

  static const List<CountryDialCode> all = [
    india,
    CountryDialCode(name: 'United States', isoCode: 'US', dialCode: '+1', nationalLength: 10),
    CountryDialCode(name: 'United Kingdom', isoCode: 'GB', dialCode: '+44', nationalLength: 10),
    CountryDialCode(name: 'United Arab Emirates', isoCode: 'AE', dialCode: '+971', nationalLength: 9),
    CountryDialCode(name: 'Saudi Arabia', isoCode: 'SA', dialCode: '+966', nationalLength: 9),
    CountryDialCode(name: 'Singapore', isoCode: 'SG', dialCode: '+65', nationalLength: 8),
    CountryDialCode(name: 'Canada', isoCode: 'CA', dialCode: '+1', nationalLength: 10),
    CountryDialCode(name: 'Australia', isoCode: 'AU', dialCode: '+61', nationalLength: 9),
    CountryDialCode(name: 'Germany', isoCode: 'DE', dialCode: '+49', nationalLength: 10),
    CountryDialCode(name: 'France', isoCode: 'FR', dialCode: '+33', nationalLength: 9),
    CountryDialCode(name: 'Qatar', isoCode: 'QA', dialCode: '+974', nationalLength: 8),
    CountryDialCode(name: 'Kuwait', isoCode: 'KW', dialCode: '+965', nationalLength: 8),
    CountryDialCode(name: 'Oman', isoCode: 'OM', dialCode: '+968', nationalLength: 8),
    CountryDialCode(name: 'Bahrain', isoCode: 'BH', dialCode: '+973', nationalLength: 8),
    CountryDialCode(name: 'Nepal', isoCode: 'NP', dialCode: '+977', nationalLength: 10),
    CountryDialCode(name: 'Bangladesh', isoCode: 'BD', dialCode: '+880', nationalLength: 10),
    CountryDialCode(name: 'Sri Lanka', isoCode: 'LK', dialCode: '+94', nationalLength: 9),
    CountryDialCode(name: 'Pakistan', isoCode: 'PK', dialCode: '+92', nationalLength: 10),
    CountryDialCode(name: 'Malaysia', isoCode: 'MY', dialCode: '+60', nationalLength: 9),
    CountryDialCode(name: 'New Zealand', isoCode: 'NZ', dialCode: '+64', nationalLength: 9),
  ];

  static CountryDialCode byIso(String iso) {
    return all.firstWhere(
      (c) => c.isoCode == iso.toUpperCase(),
      orElse: () => india,
    );
  }
}
