import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/calculator_models.dart';

void main() {
  group('CalculatorTapeItem Model Tests', () {
    test('parses from standard JSON with exact fields', () {
      final json = {
        'id': 'item-101',
        'sequence': 1,
        'value': 100.5,
        'operator': '+',
        'runningTotal': 100.5,
        'label': 'Initial deposit',
        'createdAt': '2026-10-09T10:00:00.000Z',
      };

      final item = CalculatorTapeItem.fromJson(json);

      expect(item.id, 'item-101');
      expect(item.sequence, 1);
      expect(item.value, 100.5);
      expect(item.operator, '+');
      expect(item.runningTotal, 100.5);
      expect(item.label, 'Initial deposit');
      expect(item.createdAt, isNotNull);
    });

    test('handles numeric values sent as strings or integers safely', () {
      final json = {
        'id': 'item-102',
        'sequence': '2',
        'value': '45',
        'operator': '-',
        'runningTotal': '55.5',
      };

      final item = CalculatorTapeItem.fromJson(json);

      expect(item.sequence, 2);
      expect(item.value, 45.0);
      expect(item.operator, '-');
      expect(item.runningTotal, 55.5);
      expect(item.label, isNull);
    });

    test('converts to expected request JSON body format', () {
      const item = CalculatorTapeItem(
        id: 'item-103',
        sequence: 3,
        value: 12.0,
        operator: '*',
        runningTotal: 666.0,
        label: 'Tax rate',
      );

      final json = item.toJson();

      expect(json['sequence'], 3);
      expect(json['value'], 12.0);
      expect(json['operator'], '*');
      expect(json['runningTotal'], 666.0);
      expect(json['label'], 'Tax rate');
    });
  });

  group('CalculatorSession Model Tests', () {
    test('parses session and sorts items by sequence automatically', () {
      final json = {
        'id': 'sess-001',
        'title': 'Tape - 12:30',
        'mode': 'business',
        'currency': 'INR',
        'applicationName': 'Bit Tool',
        'totalAmount': 250.0,
        'createdAt': '2026-10-09T12:30:00.000Z',
        'items': [
          {
            'id': 'item-2',
            'sequence': 2,
            'value': 150.0,
            'operator': '+',
            'runningTotal': 250.0,
          },
          {
            'id': 'item-1',
            'sequence': 1,
            'value': 100.0,
            'operator': '=',
            'runningTotal': 100.0,
          },
        ],
      };

      final session = CalculatorSession.fromJson(json);

      expect(session.id, 'sess-001');
      expect(session.title, 'Tape - 12:30');
      expect(session.mode, 'business');
      expect(session.currency, 'INR');
      expect(session.applicationName, 'Bit Tool');
      expect(session.totalAmount, 250.0);
      expect(session.items.length, 2);
      expect(session.items[0].sequence, 1);
      expect(session.items[1].sequence, 2);
    });

    test('maps correctly to CrossAppTape and CrossAppTapeStep', () {
      final session = CalculatorSession(
        id: 'sess-002',
        title: 'Tape - 15:45',
        applicationName: 'BNX Mail',
        currency: 'USD',
        totalAmount: 120.0,
        createdAt: DateTime.parse('2026-10-09T15:45:00.000Z'),
        items: [
          const CalculatorTapeItem(
            id: 'it-1',
            sequence: 1,
            value: 100.0,
            operator: '+',
            runningTotal: 100.0,
            label: 'Base',
          ),
          const CalculatorTapeItem(
            id: 'it-2',
            sequence: 2,
            value: 20.0,
            operator: '+',
            runningTotal: 120.0,
            label: 'Fee',
          ),
        ],
      );

      final tape = session.toCrossAppTape();

      expect(tape.id, 'sess-002');
      expect(tape.title, 'Tape - 15:45');
      expect(tape.totalAmount, 120.0);
      expect(tape.steps.length, 2);
      expect(tape.steps[0].label, 'Base');
      expect(tape.steps[1].value, 20.0);
      expect(tape.steps[1].runningTotal, 120.0);
    });

    test('extracts totalAmount from last item if session total is zero', () {
      const session = CalculatorSession(
        id: 'sess-003',
        title: 'Tape',
        totalAmount: 0.0,
        items: [
          CalculatorTapeItem(
            id: 'it-1',
            sequence: 1,
            value: 50.0,
            operator: '+',
            runningTotal: 50.0,
          ),
          CalculatorTapeItem(
            id: 'it-2',
            sequence: 2,
            value: 30.0,
            operator: '+',
            runningTotal: 80.0,
          ),
        ],
      );

      final tape = session.toCrossAppTape();
      expect(tape.totalAmount, 80.0);
    });
  });

  group('CompareSession and CompareItem Model Tests', () {
    test('parses CompareItem and converts to ComparisonRow', () {
      final json = {
        'id': 'cmp-item-1',
        'description': 'Office Chair',
        'valueA': 4500.0,
        'valueB': 4200.0,
        'qtyA': 2,
        'qtyB': 2,
        'discountA': 10.0,
        'discountB': 5.0,
      };

      final item = CompareItem.fromJson(json);

      expect(item.id, 'cmp-item-1');
      expect(item.description, 'Office Chair');
      expect(item.valueA, 4500.0);
      expect(item.valueB, 4200.0);
      expect(item.qtyA, 2.0);
      expect(item.discountA, 10.0);

      final row = item.toComparisonRow();
      expect(row.description, 'Office Chair');
      expect(row.valueA, 4500.0);
      expect(row.valueB, 4200.0);
      // Final A = 4500 * 2 * 0.9 = 8100
      expect(row.finalA, 8100.0);
      // Final B = 4200 * 2 * 0.95 = 7980
      expect(row.finalB, 7980.0);
    });

    test('parses CompareSession with nested items', () {
      final json = {
        'id': 'cmp-sess-1',
        'title': 'Office Supplies Comparison',
        'createdAt': '2026-10-09T14:00:00.000Z',
        'items': [
          {
            'id': 'row-1',
            'description': 'Monitor',
            'valueA': 15000,
            'valueB': 14000,
          },
        ],
      };

      final session = CompareSession.fromJson(json);

      expect(session.id, 'cmp-sess-1');
      expect(session.title, 'Office Supplies Comparison');
      expect(session.items.length, 1);
      expect(session.items[0].description, 'Monitor');

      final rows = session.toComparisonRows();
      expect(rows.length, 1);
      expect(rows[0].description, 'Monitor');
      expect(rows[0].valueA, 15000.0);
    });
  });
}
