import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/providers/currency_converter_provider.dart';
import 'package:bit_tools_backend/core/services/currency_rate_service.dart';
import 'package:bit_tools_backend/features/calculator/widgets/currency_converter_widget.dart';

void main() {
  Widget buildTestWidget(CurrencyConverterProvider provider) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<CurrencyConverterProvider>.value(
          value: provider,
          child: const SingleChildScrollView(
            child: CurrencyConverterWidget(),
          ),
        ),
      ),
    );
  }

  group('CurrencyConverterWidget UI Tests', () {
    testWidgets('Renders two currency panels, swap button, and live rate metadata', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/currencies')) {
          return http.Response(
            jsonEncode([
              {'iso_code': 'USD', 'name': 'United States Dollar', 'symbol': '\$'},
              {'iso_code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
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
      final provider = CurrencyConverterProvider(service: service);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Verify Title & Subtitle
      expect(find.text('LIVE CURRENCY CONVERTER'), findsOneWidget);
      expect(find.textContaining('Real-time reference exchange rates'), findsOneWidget);

      // Verify Left & Right currency codes displayed
      expect(find.text('USD'), findsWidgets);
      expect(find.text('INR'), findsWidgets);
      expect(find.text('United States'), findsWidgets);
      expect(find.text('India'), findsWidgets);

      // Verify Swap Button icon
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);

      // Verify Rate direct description & effective date
      expect(find.textContaining('1 USD = 96.6400 INR'), findsOneWidget);
      expect(find.textContaining('Effective: 2026-10-10'), findsOneWidget);
      expect(find.textContaining('Refreshed:'), findsOneWidget);
      expect(find.textContaining('Reference rates provided by Frankfurter API'), findsOneWidget);
    });

    testWidgets('Typing in left amount updates right side immediately', (tester) async {
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

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Find the Left amount TextField (base controller text is '100')
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Enter '50' into left field
      await tester.enterText(textFields.first, '50');
      await tester.pumpAndSettle();

      // Right field should now be 50 * 80 = 4000.00
      expect(find.text('4000.00'), findsOneWidget);
    });

    testWidgets('Typing in right amount updates left side immediately', (tester) async {
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

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      // Enter '800' into right field
      await tester.enterText(textFields.last, '800');
      await tester.pumpAndSettle();

      // Left field should now be 800 / 80 = 10.0
      expect(find.text('10.0'), findsOneWidget);
    });

    testWidgets('Clicking swap button swaps currencies and rates', (tester) async {
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

      final service = CurrencyRateService(client: mockClient);
      final provider = CurrencyConverterProvider(service: service);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(provider.baseCurrency.code, 'USD');
      expect(provider.quoteCurrency.code, 'INR');

      // Tap swap button
      final swapButton = find.byIcon(Icons.swap_horiz_rounded);
      await tester.tap(swapButton);
      await tester.pumpAndSettle();

      expect(provider.baseCurrency.code, 'INR');
      expect(provider.quoteCurrency.code, 'USD');
      expect(find.textContaining('1 INR = 0.0125'), findsOneWidget);
    });

    testWidgets('Currency picker dialog opens and filters currencies via search', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/currencies')) {
          return http.Response(
            jsonEncode([
              {'iso_code': 'USD', 'name': 'United States Dollar', 'symbol': '\$'},
              {'iso_code': 'EUR', 'name': 'Euro', 'symbol': '€'},
              {'iso_code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
              {'iso_code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
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
      final provider = CurrencyConverterProvider(service: service);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Tap the left currency picker card
      final leftPickerTrigger = find.text('United States');
      await tester.tap(leftPickerTrigger);
      await tester.pumpAndSettle();

      // Search dialog should be visible
      expect(find.text('Select Source Currency'), findsOneWidget);
      expect(find.text('Search by currency code, country, or name...'), findsOneWidget);

      // Enter search query 'Japan'
      final searchField = find.widgetWithText(TextField, 'Search by currency code, country, or name...');
      await tester.enterText(searchField, 'Japan');
      await tester.pumpAndSettle();

      // Japanese Yen should be visible
      expect(find.text('Japanese Yen'), findsOneWidget);
      expect(find.text('JPY'), findsOneWidget);

      // Select JPY
      await tester.tap(find.text('Japanese Yen'));
      await tester.pumpAndSettle();

      // Dialog closed, base currency is now JPY
      expect(provider.baseCurrency.code, 'JPY');
    });

    testWidgets('Error state appears with Retry button when pair is unsupported', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 422,
            'message': 'Unsupported currency pair.',
          }),
          422,
        );
      });

      final service = CurrencyRateService(client: mockClient);
      final provider = CurrencyConverterProvider(service: service);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Unsupported currency pair.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Refresh button triggers rate refresh', (tester) async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        if (!request.url.path.contains('/currencies')) {
          requestCount++;
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
      final provider = CurrencyConverterProvider(service: service);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      final initialRequests = requestCount;

      // Tap Refresh button
      final refreshButton = find.byTooltip('Refresh live rate');
      await tester.tap(refreshButton);
      await tester.pumpAndSettle();

      expect(requestCount, greaterThan(initialRequests));
    });
  });
}
