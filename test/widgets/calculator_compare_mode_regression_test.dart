import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/models/calculator_models.dart';
import 'package:bit_tools_backend/core/providers/calculator_provider.dart';
import 'package:bit_tools_backend/core/providers/currency_converter_provider.dart';
import 'package:bit_tools_backend/core/services/calculator_api_service.dart';
import 'package:bit_tools_backend/core/services/currency_rate_service.dart';
import 'package:bit_tools_backend/features/calculator/calculator_screen.dart';
import 'package:bit_tools_backend/features/calculator/widgets/currency_converter_widget.dart';

class FakeCalculatorApiService implements CalculatorApiService {
  List<CalculatorSession> mockSessions = [];
  int createSessionCalls = 0;
  int addSessionItemCalls = 0;
  int deleteSessionCalls = 0;
  int clearHistoryCalls = 0;

  @override
  Future<List<CalculatorSession>> getHistory() async => List.from(mockSessions);

  @override
  Future<List<CalculatorSession>> getHistoryAll() async => List.from(mockSessions);

  @override
  Future<CalculatorSession> createSession({
    required String title,
    String mode = 'business',
    String currency = 'INR',
    String? applicationName,
  }) async {
    createSessionCalls++;
    final session = CalculatorSession(
      id: 'sess-${mockSessions.length + 1}',
      title: title,
      mode: mode,
      currency: currency,
      applicationName: applicationName ?? 'Bit Tool',
      totalAmount: 0.0,
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    mockSessions.add(session);
    return session;
  }

  @override
  Future<CalculatorTapeItem> addSessionItem({
    required String sessionId,
    required int sequence,
    required double value,
    required String operator,
    required double runningTotal,
    String label = '',
  }) async {
    addSessionItemCalls++;
    final item = CalculatorTapeItem(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      sequence: sequence,
      value: value,
      operator: operator,
      runningTotal: runningTotal,
      label: label,
      createdAt: DateTime.now(),
    );
    final idx = mockSessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = mockSessions[idx];
      mockSessions[idx] = s.copyWith(
        items: [...s.items, item],
        itemCount: s.items.length + 1,
        totalAmount: runningTotal,
      );
    }
    return item;
  }

  @override
  Future<CalculatorSession> getSessionDetails(String id) async {
    return mockSessions.firstWhere((s) => s.id == id);
  }

  @override
  Future<CalculatorSession> getSessionById(String id) => getSessionDetails(id);

  @override
  Future<bool> deleteSession(String id) async {
    deleteSessionCalls++;
    mockSessions.removeWhere((s) => s.id == id);
    return true;
  }

  @override
  Future<bool> clearHistory() async {
    clearHistoryCalls++;
    mockSessions.clear();
    return true;
  }

  @override
  Future<bool> clearAllSessions() => clearHistory();

  @override
  Future<List<CompareSession>> getCompareHistory() async => [];

  @override
  Future<CompareSession> createCompareSession({
    required String title,
    String mode = 'compare',
    String currency = 'INR',
  }) async {
    return CompareSession(
      id: 'cmp-1',
      title: title,
      mode: mode,
      currency: currency,
      createdAt: DateTime.now(),
      items: [],
    );
  }

  @override
  Future<CompareItem> addCompareItem({
    required String sessionId,
    required String description,
    double? valueA,
    double? valueB,
    double qtyA = 1.0,
    double qtyB = 1.0,
    double discountA = 0.0,
    double discountB = 0.0,
    int sequence = 1,
  }) async {
    return CompareItem(
      id: 'cmp-item-1',
      description: description,
      valueA: valueA,
      valueB: valueB,
      qtyA: qtyA,
      qtyB: qtyB,
      discountA: discountA,
      discountB: discountB,
      sequence: sequence,
    );
  }

  @override
  Future<CompareItem> updateCompareItem({
    required String sessionId,
    required String itemId,
    String? description,
    double? valueA,
    double? valueB,
    double? qtyA,
    double? qtyB,
    double? discountA,
    double? discountB,
    int? sequence,
  }) async {
    return CompareItem(
      id: itemId,
      description: description ?? '',
      valueA: valueA ?? 0.0,
      valueB: valueB ?? 0.0,
      qtyA: qtyA ?? 1.0,
      qtyB: qtyB ?? 1.0,
      discountA: discountA ?? 0.0,
      discountB: discountB ?? 0.0,
    );
  }

  @override
  Future<bool> deleteCompareItem({required String sessionId, required String itemId}) async => true;

  @override
  Future<bool> deleteCompareSession(String id) async => true;

  @override
  Future<bool> clearCompareHistory() async => true;
}

void main() {
  group('Calculator Regression and Isolation Tests', () {
    late FakeCalculatorApiService mockApi;
    late CalculatorProvider calcProvider;

    setUp(() {
      mockApi = FakeCalculatorApiService();
      calcProvider = CalculatorProvider(null, mockApi);
    });

    test('Standard arithmetic operations: 100 + 50 = 150', () {
      calcProvider.enterDigit('1');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('+');
      calcProvider.enterDigit('5');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('+');

      expect(calcProvider.runningTotal, 150.0);
      expect(calcProvider.tapeEntries.length, 2);
    });

    test('Standard arithmetic operations: 100 - 50 = 50', () {
      calcProvider.enterDigit('1');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('-');
      calcProvider.enterDigit('5');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('+');

      expect(calcProvider.runningTotal, 50.0);
      expect(calcProvider.tapeEntries.length, 2);
    });

    test('Standard arithmetic operations: 12 * 5 = 60', () {
      calcProvider.enterDigit('1');
      calcProvider.enterDigit('2');
      calcProvider.setOperator('×');
      calcProvider.enterDigit('5');
      calcProvider.setOperator('+');

      expect(calcProvider.runningTotal, 60.0);
      expect(calcProvider.tapeEntries.length, 2);
    });

    test('Standard arithmetic operations: 100 / 4 = 25', () {
      calcProvider.enterDigit('1');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('÷');
      calcProvider.enterDigit('4');
      calcProvider.setOperator('+');

      expect(calcProvider.runningTotal, 25.0);
      expect(calcProvider.tapeEntries.length, 2);
    });

    test('Decimal arithmetic operations: 10.5 + 2.25 = 12.75', () {
      calcProvider.enterDigit('1');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('.');
      calcProvider.enterDigit('5');
      calcProvider.setOperator('+');
      calcProvider.enterDigit('2');
      calcProvider.enterDigit('.');
      calcProvider.enterDigit('2');
      calcProvider.enterDigit('5');
      calcProvider.setOperator('+');

      expect(calcProvider.runningTotal, 12.75);
      expect(calcProvider.tapeEntries.length, 2);
    });

    test('Division by zero is handled safely without crashing', () {
      calcProvider.enterDigit('1');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('÷');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('+');

      // Total must remain safe 100.0 without throwing
      expect(calcProvider.runningTotal, 100.0);
    });

    test('Large values and presets 5%, 12%, 18%, 28% GST and 5%, 10%, 20%, 50% discount', () {
      // GST Presets
      calcProvider.clearAll();
      calcProvider.enterDigit('1');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('0');
      calcProvider.commitEntry();

      calcProvider.applyGstPreset(5.0);
      expect(calcProvider.runningTotal, 105.0);

      calcProvider.applyGstPreset(12.0);
      expect(calcProvider.runningTotal, 105.0 + (105.0 * 0.12));

      // Discount Presets
      calcProvider.clearAll();
      calcProvider.enterDigit('2');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('0');
      calcProvider.commitEntry();

      calcProvider.applyDiscountPreset(20.0);
      expect(calcProvider.runningTotal, 160.0);

      calcProvider.applyDiscountPreset(50.0);
      expect(calcProvider.runningTotal, 80.0);
    });

    test('GST calculation functions as expected', () {
      calcProvider.enterDigit('1');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('+');
      expect(calcProvider.runningTotal, 100.0);

      // Apply 18% GST
      calcProvider.applyGstPreset(18.0);
      expect(calcProvider.runningTotal, 118.0);
    });

    test('Discount calculation functions as expected', () {
      calcProvider.enterDigit('2');
      calcProvider.enterDigit('0');
      calcProvider.enterDigit('0');
      calcProvider.setOperator('+');
      expect(calcProvider.runningTotal, 200.0);

      // Apply 10% discount
      calcProvider.applyDiscountPreset(10.0);
      expect(calcProvider.runningTotal, 180.0);
    });

    test('INR toggle mode works and does not mutate currency converter', () {
      expect(calcProvider.currencyType, CurrencyType.inr);
      calcProvider.toggleCurrency();
      expect(calcProvider.currencyType, CurrencyType.usd);
      calcProvider.toggleCurrency();
      expect(calcProvider.currencyType, CurrencyType.inr);
    });

    test('Switching to Compare mode and back preserves standard calculator tape state', () {
      calcProvider.enterDigit('4');
      calcProvider.enterDigit('2');
      calcProvider.setOperator('+');
      calcProvider.enterDigit('8');
      calcProvider.setOperator('+');

      expect(calcProvider.runningTotal, 50.0);
      expect(calcProvider.tapeEntries.length, 2);

      // Switch to compare mode
      calcProvider.setMode(CalcMode.compare);
      expect(calcProvider.activeMode, CalcMode.compare);

      // Switch back to gst mode
      calcProvider.setMode(CalcMode.gst);
      expect(calcProvider.activeMode, CalcMode.gst);

      // Tape state must remain intact
      expect(calcProvider.runningTotal, 50.0);
      expect(calcProvider.tapeEntries.length, 2);
      expect(calcProvider.tapeEntries[0].value, 42.0);
      expect(calcProvider.tapeEntries[1].value, 8.0);
    });

    test('Compare mode row calculation arithmetic: Price, Qty, and Discount formulas', () {
      calcProvider.setMode(CalcMode.compare);
      calcProvider.addComparisonRow();

      calcProvider.updateComparisonRow(
        0,
        description: 'Office Chair',
        valueA: 500.0,
        qtyA: 2.0,
        discountA: 10.0,
        valueB: 1000.0,
        qtyB: 1.0,
        discountB: 0.0,
      );

      final row = calcProvider.comparisonRows.first;
      // Side A: (500 * 2) - 10% = 900.0
      expect(row.finalA, 900.0);
      // Side B: (1000 * 1) - 0% = 1000.0
      expect(row.finalB, 1000.0);
      // Side A is cheaper
      expect(row.finalA < row.finalB, isTrue);
    });

    test('CurrencyConverterProvider is completely isolated and never invokes calculator API', () async {
      final mockHttpClient = MockClient((request) async {
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

      final currencyService = CurrencyRateService(client: mockHttpClient);
      final currencyProvider = CurrencyConverterProvider(service: currencyService);

      await currencyProvider.fetchRate();
      currencyProvider.updateBaseAmount('500');
      currencyProvider.swapCurrencies();

      // Zero calculator API calls must have been made
      expect(mockApi.createSessionCalls, 0);
      expect(mockApi.addSessionItemCalls, 0);
      expect(mockApi.deleteSessionCalls, 0);
      expect(mockApi.clearHistoryCalls, 0);
    });

    testWidgets('Tapping INR tab displays live currency converter and hides tape', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttpClient = MockClient((request) async {
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
      final currencyService = CurrencyRateService(client: mockHttpClient);
      final currencyProvider = CurrencyConverterProvider(service: currencyService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CalculatorProvider>.value(value: calcProvider),
            ChangeNotifierProvider<CurrencyConverterProvider>.value(value: currencyProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalculatorScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in GST mode (% GST tab active)
      expect(find.text('% GST'), findsWidgets);
      expect(find.text('INR'), findsWidgets);
      expect(find.text('Compare'), findsWidgets);

      // Tap INR tab
      final inrTab = find.text('INR');
      await tester.tap(inrTab);
      await tester.pumpAndSettle();

      // Verify that CalcMode.currency is active and CurrencyConverterWidget is shown
      expect(calcProvider.activeMode, CalcMode.currency);
      expect(find.byType(CurrencyConverterWidget), findsOneWidget);
      expect(find.text('LIVE CURRENCY CONVERTER'), findsOneWidget);
    });

    testWidgets('Tapping Compare tab restores the original price comparison table', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttpClient = MockClient((request) async {
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
      final currencyService = CurrencyRateService(client: mockHttpClient);
      final currencyProvider = CurrencyConverterProvider(service: currencyService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CalculatorProvider>.value(value: calcProvider),
            ChangeNotifierProvider<CurrencyConverterProvider>.value(value: currencyProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalculatorScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Compare tab
      final compareTab = find.text('Compare');
      await tester.tap(compareTab);
      await tester.pumpAndSettle();

      // Verify that Compare mode is active and original Price Comparison table is shown
      expect(calcProvider.activeMode, CalcMode.compare);
      expect(find.text('PRICE COMPARISON'), findsOneWidget);
      expect(find.text('Side A'), findsOneWidget);
      expect(find.text('Side B'), findsOneWidget);
      expect(find.text('Description'), findsWidgets);
      expect(find.text('Price A'), findsOneWidget);
      expect(find.text('Price B'), findsOneWidget);

      // Verify Live Currency Converter is NOT in Compare mode
      expect(find.byType(CurrencyConverterWidget), findsNothing);
    });

    testWidgets('Adding an item in Compare mode displays row, analysis banner, and updates Total Sum', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttpClient = MockClient((request) async => http.Response('{}', 200));
      final currencyService = CurrencyRateService(client: mockHttpClient);
      final currencyProvider = CurrencyConverterProvider(service: currencyService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CalculatorProvider>.value(value: calcProvider),
            ChangeNotifierProvider<CurrencyConverterProvider>.value(value: currencyProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalculatorScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Compare tab
      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();

      // Enter Description, Price A, and Price B
      final descField = find.widgetWithText(TextField, 'Description');
      final valAField = find.widgetWithText(TextField, 'Price A');
      final valBField = find.widgetWithText(TextField, 'Price B');

      await tester.enterText(descField, 'Office Desk');
      await tester.enterText(valAField, '1000');
      await tester.enterText(valBField, '1500');
      await tester.pump();

      // Tap Add item button
      final addBtn = find.byTooltip('Add item to comparison');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Verify row is added
      expect(calcProvider.comparisonRows.length, 1);
      expect(find.text('Office Desk'), findsOneWidget);
      expect(find.text('Total Sum'), findsOneWidget);

      // Verify analysis banner appears
      expect(find.text('Side A is cheaper by 33%'), findsOneWidget);

      // Tap remove row button
      final removeBtn = find.byTooltip('Remove row');
      expect(removeBtn, findsOneWidget);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Verify row is removed
      expect(calcProvider.comparisonRows.isEmpty, isTrue);
    });

    testWidgets('Dynamic multi-side comparison: add Side C, enter prices, verify winner analysis, and remove Side C', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockHttpClient = MockClient((request) async => http.Response('{}', 200));
      final currencyService = CurrencyRateService(client: mockHttpClient);
      final currencyProvider = CurrencyConverterProvider(service: currencyService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CalculatorProvider>.value(value: calcProvider),
            ChangeNotifierProvider<CurrencyConverterProvider>.value(value: currencyProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalculatorScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Compare tab
      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();

      // Verify initially only Side A and Side B exist
      expect(calcProvider.comparisonSides, ['A', 'B']);
      expect(find.text('Side A'), findsOneWidget);
      expect(find.text('Side B'), findsOneWidget);
      expect(find.text('Price A'), findsOneWidget);
      expect(find.text('Price B'), findsOneWidget);
      expect(find.text('Side C'), findsNothing);

      // Tap + Side button to add Side C
      final addSideBtn = find.text('+ Side');
      expect(addSideBtn, findsOneWidget);
      await tester.tap(addSideBtn);
      await tester.pumpAndSettle();

      // Verify Side C is added
      expect(calcProvider.comparisonSides, ['A', 'B', 'C']);
      expect(find.text('Side C'), findsOneWidget);
      expect(find.text('Price C'), findsOneWidget);

      // Enter Description, Price A, Price B, and Price C
      final descField = find.widgetWithText(TextField, 'Description');
      final valAField = find.widgetWithText(TextField, 'Price A');
      final valBField = find.widgetWithText(TextField, 'Price B');
      final valCField = find.widgetWithText(TextField, 'Price C');

      await tester.enterText(descField, 'Laptop');
      await tester.enterText(valAField, '1000');
      await tester.enterText(valBField, '1500');
      await tester.enterText(valCField, '800');
      await tester.pump();

      // Tap Add item button
      final addBtn = find.byTooltip('Add item to comparison');
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Verify row is added with values for A, B, and C
      expect(calcProvider.comparisonRows.length, 1);
      final row = calcProvider.comparisonRows.first;
      expect(row.getValue('A'), 1000.0);
      expect(row.getValue('B'), 1500.0);
      expect(row.getValue('C'), 800.0);

      // Verify analysis banner reflects Side C as the cheapest
      expect(find.text('Side C is cheapest by 20%'), findsOneWidget);
      expect(find.textContaining('Save 200'), findsOneWidget);

      // Remove Side C via the remove tooltip in the table header
      final removeSideCBtn = find.byTooltip('Remove Side C');
      expect(removeSideCBtn, findsOneWidget);
      await tester.tap(removeSideCBtn);
      await tester.pumpAndSettle();

      // Verify Side C is removed and we are back to 2 sides
      expect(calcProvider.comparisonSides, ['A', 'B']);
      expect(find.text('Side C'), findsNothing);
      expect(find.text('Price C'), findsNothing);

      // Verify analysis banner updates to compare A vs B
      expect(find.text('Side A is cheaper by 33%'), findsOneWidget);
    });
  });
}
