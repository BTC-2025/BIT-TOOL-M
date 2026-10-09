import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/models/calculator_models.dart';
import 'package:bit_tools_backend/core/providers/calculator_provider.dart';
import 'package:bit_tools_backend/features/calculator/models/cross_app_history_models.dart';
import 'package:bit_tools_backend/features/calculator/widgets/cross_app_history_widget.dart';
import '../providers/calculator_provider_test.dart';

Widget _buildTestApp({
  required CalculatorProvider calculatorProvider,
  Function(CrossAppTape tape)? onLoadTape,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CalculatorProvider>.value(
        value: calculatorProvider,
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: CrossAppHistoryWidget(onLoadTape: onLoadTape),
      ),
    ),
  );
}

void main() {
  group('CrossAppHistoryWidget Multi-level Navigation & API-backed Tests', () {
    late FakeCalculatorApiService fakeApi;
    late CalculatorProvider provider;

    setUp(() {
      fakeApi = FakeCalculatorApiService();
      provider = CalculatorProvider(null, fakeApi);
    });

    testWidgets('Level 1: Renders cross-app groups with real counts derived from API',
        (tester) async {
      fakeApi.mockSessions = [
        CalculatorSession(
          id: 'sess-bnx-1',
          title: 'Tape - 10:00',
          applicationName: 'BNX Mail',
          totalAmount: 150.0,
          createdAt: DateTime.now(),
        ),
        CalculatorSession(
          id: 'sess-bit-1',
          title: 'Tape - 11:00',
          applicationName: 'Bit Tool',
          totalAmount: 300.0,
          createdAt: DateTime.now(),
        ),
      ];

      await provider.fetchHistory();

      await tester.pumpWidget(_buildTestApp(calculatorProvider: provider));
      await tester.pumpAndSettle();

      // Heading
      expect(find.text('Cross-App History'), findsOneWidget);

      // Verify app titles exist
      expect(find.text('BNX Mail'), findsOneWidget);
      expect(find.text('Bit Tool'), findsOneWidget);
      expect(find.text('Cliks'), findsOneWidget);
      expect(find.text('Cliks Business'), findsOneWidget);

      // Verify counts
      expect(find.text('1 Tape saved'), findsNWidgets(2)); // BNX Mail and Bit Tool each have 1
      expect(find.text('0 Tapes saved'), findsNWidgets(2)); // Cliks and Cliks Business each have 0
    });

    testWidgets('Level 2 & 3: Navigate to tapes, open tape details, and load to calculator',
        (tester) async {
      final sessionWithItems = CalculatorSession(
        id: 'sess-bnx-1',
        title: 'Tape - 10:00',
        applicationName: 'BNX Mail',
        totalAmount: 250.0,
        createdAt: DateTime.now(),
        items: [
          const CalculatorTapeItem(
            id: 'it-1',
            sequence: 1,
            value: 100.0,
            operator: '=',
            runningTotal: 100.0,
            label: 'Base Deposit',
          ),
          const CalculatorTapeItem(
            id: 'it-2',
            sequence: 2,
            value: 150.0,
            operator: '+',
            runningTotal: 250.0,
            label: 'Addition',
          ),
        ],
      );

      fakeApi.mockSessions = [sessionWithItems];
      await provider.fetchHistory();

      CrossAppTape? loadedTape;
      await tester.pumpWidget(
        _buildTestApp(
          calculatorProvider: provider,
          onLoadTape: (tape) => loadedTape = tape,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 'BNX Mail' to open Level 2
      await tester.tap(find.text('BNX Mail'));
      await tester.pumpAndSettle();

      // Verify we are on Level 2 (Application view)
      expect(find.text('Tape - 10:00'), findsOneWidget);
      expect(find.text('₹250.00'), findsWidgets);

      // Tap on the tape to open Level 3 (Tape Details)
      await tester.tap(find.text('Tape - 10:00'));
      await tester.pumpAndSettle();

      // Verify we are on Level 3
      expect(find.text('Tape Details'), findsOneWidget);
      expect(find.text('Base Deposit'), findsOneWidget);
      expect(find.text('Addition'), findsOneWidget);
      expect(find.text('+ 150'), findsOneWidget);

      // Tap "Load to Calculator"
      expect(find.text('Load to Calculator'), findsOneWidget);
      await tester.tap(find.text('Load to Calculator'));
      await tester.pumpAndSettle();

      expect(loadedTape, isNotNull);
      expect(loadedTape!.id, 'sess-bnx-1');
      expect(loadedTape!.steps.length, 2);

      // Tap Back button to return to Level 2
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Tape Details'), findsNothing);
      expect(find.text('Tape - 10:00'), findsOneWidget);

      // Tap Back button to return to Level 1
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Cross-App History'), findsOneWidget);
    });

    testWidgets('Level 2: Delete tape session prompts confirmation and calls delete API',
        (tester) async {
      fakeApi.mockSessions = [
        CalculatorSession(
          id: 'sess-bit-del',
          title: 'Tape to Delete',
          applicationName: 'Bit Tool',
          totalAmount: 50.0,
          createdAt: DateTime.now(),
        ),
      ];

      await provider.fetchHistory();

      await tester.pumpWidget(_buildTestApp(calculatorProvider: provider));
      await tester.pumpAndSettle();

      // Open Bit Tool tapes
      await tester.tap(find.text('Bit Tool'));
      await tester.pumpAndSettle();

      expect(find.text('Tape to Delete'), findsOneWidget);

      // Tap delete icon
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Tape Session'), findsOneWidget);
      expect(find.text('Are you sure you want to permanently delete this tape session?'), findsOneWidget);

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(fakeApi.deleteSessionCalls, 1);
      expect(find.text('Tape to Delete'), findsNothing);
      expect(find.text('No saved tapes for Bit Tool'), findsOneWidget);
    });
  });
}
