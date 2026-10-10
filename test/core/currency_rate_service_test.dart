import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_tools_backend/core/services/currency_rate_service.dart';

void main() {
  group('CurrencyRateService Tests', () {
    test('Successful rate fetch with correct URL construction and field parsing', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://api.frankfurter.dev/v2/rate/USD/INR');
        expect(request.headers.containsKey('Authorization'), isFalse);

        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 96.64,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CurrencyRateService(client: mockClient);
      final rate = await service.getRate('usd', 'inr');

      expect(rate.base, 'USD');
      expect(rate.quote, 'INR');
      expect(rate.rate, 96.64);
      expect(rate.date, '2026-10-10');
      expect(rate.isStale, isFalse);
      expect(rate.fetchedAt, isNotNull);
    });

    test('Identical currency pair returns identity 1.0 rate without network request', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      final service = CurrencyRateService(client: mockClient);
      final rate = await service.getRate('EUR', 'EUR');

      expect(requestCount, 0);
      expect(rate.base, 'EUR');
      expect(rate.quote, 'EUR');
      expect(rate.rate, 1.0);
    });

    test('Currencies list parsing returns sorted list of CurrencyItem', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), 'https://api.frankfurter.dev/v2/currencies');
        return http.Response(
          jsonEncode([
            {'iso_code': 'USD', 'name': 'United States Dollar', 'symbol': '\$'},
            {'iso_code': 'EUR', 'name': 'Euro', 'symbol': '€'},
            {'iso_code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CurrencyRateService(client: mockClient);
      final currencies = await service.getCurrencies();

      expect(currencies.length, 3);
      expect(currencies[0].code, 'EUR');
      expect(currencies[1].code, 'INR');
      expect(currencies[2].code, 'USD');
      expect(currencies[1].name, 'Indian Rupee');
      expect(currencies[1].symbol, '₹');
      expect(currencies[1].countryOrRegion, 'India');
      expect(currencies[1].flag, '🇮🇳');
    });

    test('Unsupported currency pair (HTTP 422) throws UnsupportedCurrencyPairException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 422,
            'message': "Unsupported pair: 'USD' to 'XYZ'",
          }),
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = CurrencyRateService(client: mockClient);

      expect(
        () => service.getRate('USD', 'XYZ'),
        throwsA(isA<UnsupportedCurrencyPairException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported pair'),
        )),
      );
    });

    test('HTTP server error (e.g. 500) throws CurrencyRateException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = CurrencyRateService(client: mockClient);

      expect(
        () => service.getRate('USD', 'INR'),
        throwsA(isA<CurrencyRateException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });

    test('Network failure throws CurrencyNetworkException', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('Failed host lookup: api.frankfurter.dev');
      });

      final service = CurrencyRateService(client: mockClient);

      expect(
        () => service.getRate('USD', 'INR'),
        throwsA(isA<CurrencyNetworkException>().having(
          (e) => e.message,
          'message',
          contains('No internet connection'),
        )),
      );
    });

    test('Timeout throws CurrencyNetworkException', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Request timed out');
      });

      final service = CurrencyRateService(client: mockClient);

      expect(
        () => service.getRate('USD', 'INR'),
        throwsA(isA<CurrencyNetworkException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        )),
      );
    });

    test('Invalid JSON throws CurrencyRateException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('<html>Bad Gateway</html>', 200);
      });

      final service = CurrencyRateService(client: mockClient);

      expect(
        () => service.getRate('USD', 'INR'),
        throwsA(isA<CurrencyRateException>()),
      );
    });

    test('Cache reuse and forceRefresh behavior', () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        apiCallCount++;
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 96.64,
          }),
          200,
        );
      });

      final service = CurrencyRateService(client: mockClient);

      // First call fetches from network
      final r1 = await service.getRate('USD', 'INR');
      expect(apiCallCount, 1);
      expect(r1.rate, 96.64);

      // Second call uses in-memory cache
      final r2 = await service.getRate('USD', 'INR');
      expect(apiCallCount, 1);
      expect(r2.rate, 96.64);

      // Inverse pair USD/INR was also populated in cache (INR/USD)
      final rInverse = await service.getRate('INR', 'USD');
      expect(apiCallCount, 1);
      expect(rInverse.rate, closeTo(1.0 / 96.64, 0.0001));

      // Force refresh bypasses cache
      final r3 = await service.getRate('USD', 'INR', forceRefresh: true);
      expect(apiCallCount, 2);
      expect(r3.rate, 96.64);
    });

    test('Stale cached rate is returned with isStale=true on subsequent network failure', () async {
      bool shouldFail = false;
      final mockClient = MockClient((request) async {
        if (shouldFail) {
          throw const SocketException('Network down');
        }
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 96.64,
          }),
          200,
        );
      });

      final service = CurrencyRateService(client: mockClient);

      // Successful first fetch
      final firstRate = await service.getRate('USD', 'INR');
      expect(firstRate.isStale, isFalse);

      // Network goes down, force refresh requested
      shouldFail = true;
      final fallbackRate = await service.getRate('USD', 'INR', forceRefresh: true);
      expect(fallbackRate.rate, 96.64);
      expect(fallbackRate.isStale, isTrue);
    });
  });
}
