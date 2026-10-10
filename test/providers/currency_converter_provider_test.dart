import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_tools_backend/core/models/currency_models.dart';
import 'package:bit_tools_backend/core/providers/currency_converter_provider.dart';
import 'package:bit_tools_backend/core/services/currency_rate_service.dart';

void main() {
  group('CurrencyConverterProvider Conversion Logic Tests', () {
    test('USD to INR using mocked rate calculates right side immediately', () async {
      final mockClient = MockClient((request) async {
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
      final provider = CurrencyConverterProvider(service: service);

      // Default left amount is 100
      expect(provider.baseAmountController.text, '100');

      await provider.fetchRate();

      expect(provider.currentRate, isNotNull);
      expect(provider.currentRate!.rate, 96.64);
      // 100 * 96.64 = 9664.00
      expect(provider.quoteAmountController.text, '9664.00');
      expect(provider.formatDisplayValue(provider.quoteAmountController.text, provider.quoteCurrency), '₹9,664.00');
    });

    test('Editing left input updates right input (A * R)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 80.0,
          }),
          200,
        );
      });

      final service = CurrencyRateService(client: mockClient);
      final provider = CurrencyConverterProvider(service: service);
      await provider.fetchRate();

      provider.updateBaseAmount('250');
      // 250 * 80 = 20000.00
      expect(provider.quoteAmountController.text, '20000.00');
      expect(provider.activeSide, CurrencySide.left);
    });

    test('Editing right input updates left input using inverse (B / R)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 80.0,
          }),
          200,
        );
      });

      final service = CurrencyRateService(client: mockClient);
      final provider = CurrencyConverterProvider(service: service);
      await provider.fetchRate();

      provider.updateQuoteAmount('1600');
      // 1600 / 80 = 20.0
      expect(double.parse(provider.baseAmountController.text), 20.0);
      expect(provider.activeSide, CurrencySide.right);
    });

    test('Empty input clears the opposite side', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 80.0,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      await provider.fetchRate();

      provider.updateBaseAmount('');
      expect(provider.quoteAmountController.text, '');

      provider.updateQuoteAmount('');
      expect(provider.baseAmountController.text, '');
    });

    test('Zero input sets opposite side to 0', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 80.0,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      await provider.fetchRate();

      provider.updateBaseAmount('0');
      expect(provider.quoteAmountController.text, '0');

      provider.updateQuoteAmount('0');
      expect(provider.baseAmountController.text, '0');
    });

    test('Decimal input and rounding precision', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'EUR',
            'rate': 0.8543,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      provider.setQuoteCurrency(const CurrencyItem(
        code: 'EUR',
        name: 'Euro',
        symbol: '€',
        countryOrRegion: 'European Union',
        flag: '🇪🇺',
      ));
      await provider.fetchRate();

      provider.updateBaseAmount('12.5');
      // 12.5 * 0.8543 = 10.67875 -> formatted to up to 4 decimals
      expect(double.parse(provider.quoteAmountController.text), closeTo(10.6788, 0.001));
    });

    test('Large values handled without overflow or error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 90.0,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      await provider.fetchRate();

      provider.updateBaseAmount('100000000'); // 100 million
      expect(provider.quoteAmountController.text, '9000000000.00'); // 9 billion
    });

    test('Invalid input clears opposite side', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 80.0,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      await provider.fetchRate();

      provider.updateBaseAmount('abc');
      expect(provider.quoteAmountController.text, '');
    });

    test('Swapping currencies reverses base and quote and swaps amount values', () async {
      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('INR/USD')) {
          return http.Response(
            jsonEncode({
              'date': '2026-10-10',
              'base': 'INR',
              'quote': 'USD',
              'rate': 0.0125,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 80.0,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      await provider.fetchRate();

      expect(provider.baseCurrency.code, 'USD');
      expect(provider.quoteCurrency.code, 'INR');
      expect(provider.baseAmountController.text, '100');
      expect(provider.quoteAmountController.text, '8000.00');

      // Swap
      provider.swapCurrencies();
      await Future.delayed(Duration.zero); // await async fetch

      expect(provider.baseCurrency.code, 'INR');
      expect(provider.quoteCurrency.code, 'USD');
      // Amounts swapped
      expect(provider.baseAmountController.text, '8000.00');
    });

    test('Rate description direct and inverse string formatting', () async {
      final mockClient = MockClient((request) async {
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

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      await provider.fetchRate();

      expect(provider.rateDescriptionDirect, '1 USD = 96.6400 INR');
      expect(provider.rateDescriptionInverse, contains('1 INR ='));
      expect(provider.rateDescriptionInverse, contains('USD'));
    });

    test('Section 4 & 6 Test A & B: USD to PKR 100 -> 27,718.00 and 250 -> 69,295.00, and reverse 27,718 -> 100', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'PKR',
            'rate': 277.18,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      provider.setQuoteCurrency(const CurrencyItem(
        code: 'PKR',
        name: 'Pakistani Rupee',
        symbol: '₨',
        countryOrRegion: 'Pakistan',
        flag: '🇵🇰',
      ));
      await provider.fetchRate();

      // Test A step 1: 100 USD -> 27,718.00 PKR
      expect(provider.baseAmountController.text, '100');
      expect(provider.quoteAmountController.text, '27718.00');
      expect(provider.formatDisplayValue(provider.quoteAmountController.text, provider.quoteCurrency), '₨27,718.00');

      // Test A step 2: Change to 250 USD -> 69,295.00 PKR
      final initialRequests = requestCount;
      provider.updateBaseAmount('250');
      expect(provider.quoteAmountController.text, '69295.00');
      expect(provider.formatDisplayValue(provider.quoteAmountController.text, provider.quoteCurrency), '₨69,295.00');
      // No extra API call made on keystroke!
      expect(requestCount, initialRequests);

      // Test B: Enter 27,718 PKR on right -> 100.0 USD on left
      provider.updateQuoteAmount('27718');
      expect(double.parse(provider.baseAmountController.text), 100.0);
      expect(requestCount, initialRequests);
    });

    test('Section 6 Test D: Same-currency conversion (USD to USD, INR to INR) returns rate 1.0 without API call', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      provider.setQuoteCurrency(provider.baseCurrency); // Both are USD
      await provider.fetchRate();

      expect(requestCount, 0); // No network call
      expect(provider.currentRate, isNotNull);
      expect(provider.currentRate!.rate, 1.0);
      expect(provider.baseAmountController.text, '100');
      expect(provider.quoteAmountController.text, '100.0');

      // Update to 50 on left -> 50 on right
      provider.updateBaseAmount('50');
      expect(provider.quoteAmountController.text, '50.0');
    });

    test('Section 6 Test C: Repeated swaps do not suffer from rounding drift', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'PKR',
            'rate': 277.18,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      provider.setQuoteCurrency(const CurrencyItem(
        code: 'PKR',
        name: 'Pakistani Rupee',
        symbol: '₨',
        countryOrRegion: 'Pakistan',
        flag: '🇵🇰',
      ));
      await provider.fetchRate();

      expect(provider.baseAmountController.text, '100');
      expect(provider.quoteAmountController.text, '27718.00');

      // Swap 1: PKR -> USD
      provider.swapCurrencies();
      await Future.delayed(Duration.zero);
      expect(provider.baseCurrency.code, 'PKR');
      expect(provider.quoteCurrency.code, 'USD');
      expect(double.parse(provider.baseAmountController.text), 27718.0);
      expect(double.parse(provider.quoteAmountController.text), closeTo(100.0, 0.01));

      // Swap 2: USD -> PKR
      provider.swapCurrencies();
      await Future.delayed(Duration.zero);
      expect(provider.baseCurrency.code, 'USD');
      expect(provider.quoteCurrency.code, 'PKR');
      expect(double.parse(provider.baseAmountController.text), closeTo(100.0, 0.01));
      expect(double.parse(provider.quoteAmountController.text), closeTo(27718.0, 0.01));
    });

    test('Section 6 Test E: Leading zeros and negative values handled safely', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'date': '2026-10-10',
            'base': 'USD',
            'quote': 'INR',
            'rate': 80.0,
          }),
          200,
        );
      });

      final provider = CurrencyConverterProvider(service: CurrencyRateService(client: mockClient));
      await provider.fetchRate();

      // Leading zeros: '0050' parsed as 50
      provider.updateBaseAmount('0050');
      expect(provider.quoteAmountController.text, '4000.00');

      // Negative values: '-50'
      provider.updateBaseAmount('-50');
      expect(provider.quoteAmountController.text, '-4000.00');
    });
  });
}
