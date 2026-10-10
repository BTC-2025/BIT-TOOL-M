import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/currency_models.dart';

/// Base exception for currency rate operations.
class CurrencyRateException implements Exception {
  final String message;
  final int? statusCode;

  const CurrencyRateException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Thrown when network connection fails or requests time out.
class CurrencyNetworkException extends CurrencyRateException {
  const CurrencyNetworkException(super.message, [super.statusCode]);
}

/// Thrown when the requested currency pair is unsupported or invalid.
class UnsupportedCurrencyPairException extends CurrencyRateException {
  const UnsupportedCurrencyPairException(super.message, [super.statusCode]);
}

/// Dedicated service for live exchange rates and currency listings using the Frankfurter public API.
class CurrencyRateService {
  static const String _baseUrl = 'https://api.frankfurter.dev/v2';
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _cacheTtl = Duration(minutes: 30);

  final http.Client _client;

  /// In-memory cache keyed by "BASE_QUOTE".
  final Map<String, CurrencyRate> _rateCache = {};

  /// In-memory cache for currencies.
  List<CurrencyItem>? _currenciesCache;
  DateTime? _currenciesFetchedAt;

  CurrencyRateService({http.Client? client}) : _client = client ?? http.Client();

  /// Currencies available as guaranteed baseline fallback.
  static const List<CurrencyItem> defaultFallbackCurrencies = [
    CurrencyItem(
      code: 'USD',
      name: 'United States Dollar',
      symbol: '\$',
      countryOrRegion: 'United States',
      flag: '🇺🇸',
    ),
    CurrencyItem(
      code: 'INR',
      name: 'Indian Rupee',
      symbol: '₹',
      countryOrRegion: 'India',
      flag: '🇮🇳',
    ),
    CurrencyItem(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      countryOrRegion: 'European Union',
      flag: '🇪🇺',
    ),
    CurrencyItem(
      code: 'GBP',
      name: 'British Pound',
      symbol: '£',
      countryOrRegion: 'United Kingdom',
      flag: '🇬🇧',
    ),
    CurrencyItem(
      code: 'JPY',
      name: 'Japanese Yen',
      symbol: '¥',
      countryOrRegion: 'Japan',
      flag: '🇯🇵',
    ),
    CurrencyItem(
      code: 'CAD',
      name: 'Canadian Dollar',
      symbol: '\$',
      countryOrRegion: 'Canada',
      flag: '🇨🇦',
    ),
    CurrencyItem(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: '\$',
      countryOrRegion: 'Australia',
      flag: '🇦🇺',
    ),
    CurrencyItem(
      code: 'CHF',
      name: 'Swiss Franc',
      symbol: 'CHF',
      countryOrRegion: 'Switzerland',
      flag: '🇨🇭',
    ),
    CurrencyItem(
      code: 'CNY',
      name: 'Chinese Renminbi',
      symbol: '¥',
      countryOrRegion: 'China',
      flag: '🇨🇳',
    ),
    CurrencyItem(
      code: 'AED',
      name: 'UAE Dirham',
      symbol: 'د.إ',
      countryOrRegion: 'United Arab Emirates',
      flag: '🇦🇪',
    ),
    CurrencyItem(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: '\$',
      countryOrRegion: 'Singapore',
      flag: '🇸🇬',
    ),
  ];

  /// Retrieves supported currencies from GET /v2/currencies.
  Future<List<CurrencyItem>> getCurrencies({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _currenciesCache != null &&
        _currenciesFetchedAt != null &&
        now.difference(_currenciesFetchedAt!) < _cacheTtl) {
      return List.unmodifiable(_currenciesCache!);
    }

    final url = Uri.parse('$_baseUrl/currencies');
    try {
      final response = await _client.get(url).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final items = <CurrencyItem>[];
          for (final raw in decoded) {
            if (raw is Map<String, dynamic>) {
              final item = CurrencyItem.fromJson(raw);
              if (item.code.isNotEmpty) {
                items.add(item);
              }
            }
          }
          if (items.isNotEmpty) {
            // Sort alphabetically by currency code
            items.sort((a, b) => a.code.compareTo(b.code));
            _currenciesCache = items;
            _currenciesFetchedAt = now;
            return List.unmodifiable(items);
          }
        }
      }

      if (_currenciesCache != null) {
        return List.unmodifiable(_currenciesCache!);
      }
      return defaultFallbackCurrencies;
    } on SocketException catch (e) {
      if (kDebugMode) debugPrint('[CurrencyRateService] Network socket error: $e');
      if (_currenciesCache != null) return List.unmodifiable(_currenciesCache!);
      return defaultFallbackCurrencies;
    } on TimeoutException catch (e) {
      if (kDebugMode) debugPrint('[CurrencyRateService] Currencies fetch timeout: $e');
      if (_currenciesCache != null) return List.unmodifiable(_currenciesCache!);
      return defaultFallbackCurrencies;
    } catch (e) {
      if (kDebugMode) debugPrint('[CurrencyRateService] Unexpected currencies error: $e');
      if (_currenciesCache != null) return List.unmodifiable(_currenciesCache!);
      return defaultFallbackCurrencies;
    }
  }

  /// Retrieves exchange rate between base and quote currencies.
  /// If forceRefresh is false, returns cached rate if available.
  Future<CurrencyRate> getRate(
    String base,
    String quote, {
    bool forceRefresh = false,
  }) async {
    final cleanBase = base.trim().toUpperCase();
    final cleanQuote = quote.trim().toUpperCase();

    if (cleanBase.isEmpty || cleanQuote.isEmpty) {
      throw const CurrencyRateException('Currency codes cannot be empty.');
    }

    // Identical currency pair has an intrinsic rate of 1.0
    if (cleanBase == cleanQuote) {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final identityRate = CurrencyRate(
        base: cleanBase,
        quote: cleanQuote,
        rate: 1.0,
        date: todayStr,
        fetchedAt: DateTime.now(),
        isStale: false,
      );
      _rateCache['${cleanBase}_$cleanQuote'] = identityRate;
      return identityRate;
    }

    final cacheKey = '${cleanBase}_$cleanQuote';
    final cached = _rateCache[cacheKey];

    if (!forceRefresh && cached != null) {
      final age = DateTime.now().difference(cached.fetchedAt);
      if (age < _cacheTtl && !cached.isStale) {
        return cached;
      }
    }

    final url = Uri.parse('$_baseUrl/rate/$cleanBase/$cleanQuote');

    try {
      final response = await _client.get(url).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final rate = CurrencyRate.fromJson(decoded, fetchedAt: DateTime.now(), isStale: false);
          _rateCache[cacheKey] = rate;

          // Also populate inverse in cache if valid rate > 0
          if (rate.rate > 0) {
            final inverseKey = '${cleanQuote}_$cleanBase';
            _rateCache[inverseKey] = CurrencyRate(
              base: cleanQuote,
              quote: cleanBase,
              rate: 1.0 / rate.rate,
              date: rate.date,
              fetchedAt: rate.fetchedAt,
              isStale: false,
            );
          }

          return rate;
        }
        throw const CurrencyRateException('Malformed response received from exchange rate API.');
      } else if (response.statusCode == 422) {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final msg = decoded['message']?.toString() ?? 'Unsupported currency pair.';
          throw UnsupportedCurrencyPairException(msg, 422);
        } catch (e) {
          if (e is UnsupportedCurrencyPairException) rethrow;
          throw UnsupportedCurrencyPairException(
            'Currency pair $cleanBase/$cleanQuote is unsupported by exchange provider.',
            422,
          );
        }
      } else {
        // Non-200 / Non-422 error
        if (cached != null) {
          return cached.copyWith(isStale: true);
        }
        throw CurrencyRateException(
          'Failed to fetch rate for $cleanBase/$cleanQuote (HTTP ${response.statusCode}).',
          response.statusCode,
        );
      }
    } on SocketException catch (_) {
      if (cached != null) {
        return cached.copyWith(isStale: true);
      }
      throw CurrencyNetworkException('No internet connection. Unable to fetch $cleanBase/$cleanQuote rate.');
    } on TimeoutException catch (_) {
      if (cached != null) {
        return cached.copyWith(isStale: true);
      }
      throw CurrencyNetworkException('Connection timed out while fetching $cleanBase/$cleanQuote rate.');
    } on http.ClientException catch (e) {
      if (cached != null) {
        return cached.copyWith(isStale: true);
      }
      throw CurrencyNetworkException('Network error: ${e.message}');
    } catch (e) {
      if (e is CurrencyRateException) rethrow;
      if (cached != null) {
        return cached.copyWith(isStale: true);
      }
      throw CurrencyRateException('Failed to retrieve rate: $e');
    }
  }

  /// Clears in-memory caches.
  void clearCache() {
    _rateCache.clear();
    _currenciesCache = null;
    _currenciesFetchedAt = null;
  }
}
