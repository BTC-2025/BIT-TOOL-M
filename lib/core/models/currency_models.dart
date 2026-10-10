import 'package:flutter/foundation.dart';

/// Metadata lookup for country/region names and flag emojis for ISO 4217 currency codes.
const Map<String, ({String country, String flag})> _currencyMetadata = {
  'USD': (country: 'United States', flag: '🇺🇸'),
  'INR': (country: 'India', flag: '🇮🇳'),
  'EUR': (country: 'European Union', flag: '🇪🇺'),
  'GBP': (country: 'United Kingdom', flag: '🇬🇧'),
  'JPY': (country: 'Japan', flag: '🇯🇵'),
  'CAD': (country: 'Canada', flag: '🇨🇦'),
  'AUD': (country: 'Australia', flag: '🇦🇺'),
  'CHF': (country: 'Switzerland', flag: '🇨🇭'),
  'CNY': (country: 'China', flag: '🇨🇳'),
  'AED': (country: 'United Arab Emirates', flag: '🇦🇪'),
  'SGD': (country: 'Singapore', flag: '🇸🇬'),
  'NZD': (country: 'New Zealand', flag: '🇳🇿'),
  'BRL': (country: 'Brazil', flag: '🇧🇷'),
  'ZAR': (country: 'South Africa', flag: '🇿🇦'),
  'MXN': (country: 'Mexico', flag: '🇲🇽'),
  'KRW': (country: 'South Korea', flag: '🇰🇷'),
  'SEK': (country: 'Sweden', flag: '🇸🇪'),
  'NOK': (country: 'Norway', flag: '🇳🇴'),
  'DKK': (country: 'Denmark', flag: '🇩🇰'),
  'PLN': (country: 'Poland', flag: '🇵🇱'),
  'THB': (country: 'Thailand', flag: '🇹🇭'),
  'IDR': (country: 'Indonesia', flag: '🇮🇩'),
  'MYR': (country: 'Malaysia', flag: '🇲🇾'),
  'PHP': (country: 'Philippines', flag: '🇵🇭'),
  'TRY': (country: 'Turkey', flag: '🇹🇷'),
  'RUB': (country: 'Russia', flag: '🇷🇺'),
  'SAR': (country: 'Saudi Arabia', flag: '🇸🇦'),
  'QAR': (country: 'Qatar', flag: '🇶🇦'),
  'KWD': (country: 'Kuwait', flag: '🇰🇼'),
  'BHD': (country: 'Bahrain', flag: '🇧🇭'),
  'OMR': (country: 'Oman', flag: '🇴🇲'),
  'EGP': (country: 'Egypt', flag: '🇪🇬'),
  'ILS': (country: 'Israel', flag: '🇮🇱'),
  'PKR': (country: 'Pakistan', flag: '🇵🇰'),
  'BDT': (country: 'Bangladesh', flag: '🇧🇩'),
  'LKR': (country: 'Sri Lanka', flag: '🇱🇰'),
  'VND': (country: 'Vietnam', flag: '🇻🇳'),
  'NGN': (country: 'Nigeria', flag: '🇳🇬'),
  'KES': (country: 'Kenya', flag: '🇰🇪'),
  'GHS': (country: 'Ghana', flag: '🇬🇭'),
  'CLP': (country: 'Chile', flag: '🇨🇱'),
  'COP': (country: 'Colombia', flag: '🇨🇴'),
  'ARS': (country: 'Argentina', flag: '🇦🇷'),
  'PEN': (country: 'Peru', flag: '🇵🇪'),
  'CZK': (country: 'Czech Republic', flag: '🇨🇿'),
  'HUF': (country: 'Hungary', flag: '🇭🇺'),
  'RON': (country: 'Romania', flag: '🇷🇴'),
  'BGN': (country: 'Bulgaria', flag: '🇧🇬'),
  'HRK': (country: 'Croatia', flag: '🇭🇷'),
  'ISK': (country: 'Iceland', flag: '🇮🇸'),
  'HKD': (country: 'Hong Kong', flag: '🇭🇰'),
  'TWD': (country: 'Taiwan', flag: '🇹🇼'),
  'UAH': (country: 'Ukraine', flag: '🇺🇦'),
  'JOD': (country: 'Jordan', flag: '🇯🇴'),
  'MAD': (country: 'Morocco', flag: '🇲🇦'),
  'DZD': (country: 'Algeria', flag: '🇩🇿'),
  'TND': (country: 'Tunisia', flag: '🇹🇳'),
  'IQD': (country: 'Iraq', flag: '🇮🇶'),
  'AFN': (country: 'Afghanistan', flag: '🇦🇫'),
  'ALL': (country: 'Albania', flag: '🇦🇱'),
  'AMD': (country: 'Armenia', flag: '🇦🇲'),
  'AOA': (country: 'Angola', flag: '🇦🇴'),
  'AWG': (country: 'Aruba', flag: '🇦🇼'),
  'AZN': (country: 'Azerbaijan', flag: '🇦🇿'),
  'BAM': (country: 'Bosnia and Herzegovina', flag: '🇧🇦'),
  'BBD': (country: 'Barbados', flag: '🇧🇧'),
  'BIF': (country: 'Burundi', flag: '🇧🇮'),
  'BMD': (country: 'Bermuda', flag: '🇧🇲'),
  'BND': (country: 'Brunei', flag: '🇧🇳'),
  'BOB': (country: 'Bolivia', flag: '🇧🇴'),
  'BSD': (country: 'Bahamas', flag: '🇧🇸'),
  'BTN': (country: 'Bhutan', flag: '🇧🇹'),
  'BWP': (country: 'Botswana', flag: '🇧🇼'),
  'BYN': (country: 'Belarus', flag: '🇧🇾'),
  'BZD': (country: 'Belize', flag: '🇧🇿'),
  'CDF': (country: 'Democratic Republic of the Congo', flag: '🇨🇩'),
  'CRC': (country: 'Costa Rica', flag: '🇨🇷'),
  'CUP': (country: 'Cuba', flag: '🇨🇺'),
  'CVE': (country: 'Cape Verde', flag: '🇨🇻'),
  'DJF': (country: 'Djibouti', flag: '🇩🇯'),
  'DOP': (country: 'Dominican Republic', flag: '🇩🇴'),
  'ETB': (country: 'Ethiopia', flag: '🇪🇹'),
  'FJD': (country: 'Fiji', flag: '🇫🇯'),
  'GEL': (country: 'Georgia', flag: '🇬🇪'),
  'GIP': (country: 'Gibraltar', flag: '🇬🇮'),
  'GMD': (country: 'Gambia', flag: '🇬🇲'),
  'GNF': (country: 'Guinea', flag: '🇬🇳'),
  'GTQ': (country: 'Guatemala', flag: '🇬🇹'),
  'GYD': (country: 'Guyana', flag: '🇬🇾'),
  'HNL': (country: 'Honduras', flag: '🇭🇳'),
  'HTG': (country: 'Haiti', flag: '🇭🇹'),
  'JMD': (country: 'Jamaica', flag: '🇯🇲'),
  'KGS': (country: 'Kyrgyzstan', flag: '🇰🇬'),
  'KHR': (country: 'Cambodia', flag: '🇰🇭'),
  'KMF': (country: 'Comoros', flag: '🇰🇲'),
  'KZT': (country: 'Kazakhstan', flag: '🇰🇿'),
  'LAK': (country: 'Laos', flag: '🇱🇦'),
  'LBP': (country: 'Lebanon', flag: '🇱🇧'),
  'LRD': (country: 'Liberia', flag: '🇱🇷'),
  'LSL': (country: 'Lesotho', flag: '🇱🇸'),
  'LYD': (country: 'Libya', flag: '🇱🇾'),
  'MDL': (country: 'Moldova', flag: '🇲🇩'),
  'MGA': (country: 'Madagascar', flag: '🇲🇬'),
  'MKD': (country: 'North Macedonia', flag: '🇲🇰'),
  'MMK': (country: 'Myanmar', flag: '🇲🇲'),
  'MNT': (country: 'Mongolia', flag: '🇲🇳'),
  'MOP': (country: 'Macau', flag: '🇲🇴'),
  'MRU': (country: 'Mauritania', flag: '🇲🇷'),
  'MUR': (country: 'Mauritius', flag: '🇲🇺'),
  'MVR': (country: 'Maldives', flag: '🇲🇻'),
  'MWK': (country: 'Malawi', flag: '🇲🇼'),
  'MZN': (country: 'Mozambique', flag: '🇲🇿'),
  'NAD': (country: 'Namibia', flag: '🇳🇦'),
  'NIO': (country: 'Nicaragua', flag: '🇳🇮'),
  'NPR': (country: 'Nepal', flag: '🇳🇵'),
  'PAB': (country: 'Panama', flag: '🇵🇦'),
  'PGK': (country: 'Papua New Guinea', flag: '🇵🇬'),
  'PYG': (country: 'Paraguay', flag: '🇵🇾'),
  'RSD': (country: 'Serbia', flag: '🇷🇸'),
  'RWF': (country: 'Rwanda', flag: '🇷🇼'),
  'SBD': (country: 'Solomon Islands', flag: '🇸🇧'),
  'SCR': (country: 'Seychelles', flag: '🇸🇨'),
  'SDG': (country: 'Sudan', flag: '🇸🇩'),
  'SHP': (country: 'Saint Helena', flag: '🇸🇭'),
  'SLE': (country: 'Sierra Leone', flag: '🇸🇱'),
  'SOS': (country: 'Somalia', flag: '🇸🇴'),
  'SRD': (country: 'Suriname', flag: '🇸🇷'),
  'SSP': (country: 'South Sudan', flag: '🇸🇸'),
  'STN': (country: 'Sao Tome and Principe', flag: '🇸🇹'),
  'SYP': (country: 'Syria', flag: '🇸🇾'),
  'SZL': (country: 'Eswatini', flag: '🇸🇿'),
  'TJS': (country: 'Tajikistan', flag: '🇹🇯'),
  'TMT': (country: 'Turkmenistan', flag: '🇹🇲'),
  'TOP': (country: 'Tonga', flag: '🇹🇴'),
  'TTD': (country: 'Trinidad and Tobago', flag: '🇹🇹'),
  'TZS': (country: 'Tanzania', flag: '🇹🇿'),
  'UGX': (country: 'Uganda', flag: '🇺🇬'),
  'UYU': (country: 'Uruguay', flag: '🇺🇾'),
  'UZS': (country: 'Uzbekistan', flag: '🇺🇿'),
  'VES': (country: 'Venezuela', flag: '🇻🇪'),
  'VUV': (country: 'Vanuatu', flag: '🇻🇺'),
  'WST': (country: 'Samoa', flag: '🇼🇸'),
  'XAF': (country: 'Central Africa (BEAC)', flag: '🌍'),
  'XOF': (country: 'West Africa (BCEAO)', flag: '🌍'),
  'XCD': (country: 'Eastern Caribbean', flag: '🏝️'),
  'XPF': (country: 'French Pacific (CFP)', flag: '🇵🇫'),
  'XAU': (country: 'Gold (Troy Ounce)', flag: '🪙'),
  'XAG': (country: 'Silver (Troy Ounce)', flag: '🥈'),
  'XPT': (country: 'Platinum', flag: '🪙'),
  'XPD': (country: 'Palladium', flag: '🪙'),
  'XDR': (country: 'Special Drawing Rights (IMF)', flag: '🌐'),
  'YER': (country: 'Yemen', flag: '🇾🇪'),
  'ZMW': (country: 'Zambia', flag: '🇿🇲'),
  'ZWG': (country: 'Zimbabwe', flag: '🇿🇼'),
};

/// Represents a currency option returned from Frankfurter API or fallback catalog.
@immutable
class CurrencyItem {
  final String code;
  final String name;
  final String symbol;
  final String countryOrRegion;
  final String flag;

  const CurrencyItem({
    required this.code,
    required this.name,
    required this.symbol,
    required this.countryOrRegion,
    required this.flag,
  });

  /// Factory parser for Frankfurter GET /v2/currencies response items.
  factory CurrencyItem.fromJson(Map<String, dynamic> json) {
    final rawCode = (json['iso_code'] ?? json['code'] ?? '').toString().trim().toUpperCase();
    final rawName = (json['name'] ?? '').toString().trim();
    final rawSymbol = (json['symbol'] ?? '').toString().trim();

    final meta = _currencyMetadata[rawCode];
    String country;
    String flag;

    if (meta != null) {
      country = meta.country;
      flag = meta.flag;
    } else if (rawCode.length >= 2 && RegExp(r'^[A-Z]{2}').hasMatch(rawCode)) {
      // Automatic flag generator from ISO country code if standard
      final c0 = rawCode.codeUnitAt(0);
      final c1 = rawCode.codeUnitAt(1);
      flag = String.fromCharCode(0x1F1E6 + c0 - 65) + String.fromCharCode(0x1F1E6 + c1 - 65);
      country = rawName.isNotEmpty ? rawName : rawCode;
    } else {
      flag = '🌐';
      country = rawName.isNotEmpty ? rawName : rawCode;
    }

    return CurrencyItem(
      code: rawCode,
      name: rawName.isNotEmpty ? rawName : rawCode,
      symbol: rawSymbol.isNotEmpty ? rawSymbol : rawCode,
      countryOrRegion: country,
      flag: flag,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'countryOrRegion': countryOrRegion,
        'flag': flag,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyItem && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$code ($name, $countryOrRegion)';
}

/// Represents the live exchange rate between two currencies.
@immutable
class CurrencyRate {
  final String base;
  final String quote;
  final double rate;
  final String date;
  final DateTime fetchedAt;
  final bool isStale;

  const CurrencyRate({
    required this.base,
    required this.quote,
    required this.rate,
    required this.date,
    required this.fetchedAt,
    this.isStale = false,
  });

  /// Factory parser for Frankfurter GET /v2/rate/{base}/{quote} response.
  factory CurrencyRate.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
    bool isStale = false,
  }) {
    final rawBase = (json['base'] ?? '').toString().trim().toUpperCase();
    final rawQuote = (json['quote'] ?? '').toString().trim().toUpperCase();
    final rawDate = (json['date'] ?? '').toString().trim();
    final rawRate = (json['rate'] as num?)?.toDouble() ?? 0.0;

    return CurrencyRate(
      base: rawBase,
      quote: rawQuote,
      rate: rawRate,
      date: rawDate.isNotEmpty ? rawDate : DateTime.now().toIso8601String().substring(0, 10),
      fetchedAt: fetchedAt ?? DateTime.now(),
      isStale: isStale,
    );
  }

  CurrencyRate copyWith({
    String? base,
    String? quote,
    double? rate,
    String? date,
    DateTime? fetchedAt,
    bool? isStale,
  }) {
    return CurrencyRate(
      base: base ?? this.base,
      quote: quote ?? this.quote,
      rate: rate ?? this.rate,
      date: date ?? this.date,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyRate &&
          runtimeType == other.runtimeType &&
          base == other.base &&
          quote == other.quote &&
          rate == other.rate &&
          date == other.date &&
          isStale == other.isStale;

  @override
  int get hashCode => Object.hash(base, quote, rate, date, isStale);

  @override
  String toString() => '1 $base = $rate $quote (effective: $date, stale: $isStale)';
}
