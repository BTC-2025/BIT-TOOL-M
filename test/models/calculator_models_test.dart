import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/calculator_models.dart';

void main() {
  group('TapeEntry Model', () {
    test('serializes and deserializes correctly to/from JSON', () {
      final entry = TapeEntry(
        id: 'tape-1',
        operator: '+GST',
        value: 18.0,
        runningTotal: 118.0,
        label: 'Taxes',
        isBase: false,
        presetTag: '18% GST',
      );

      final json = entry.toJson();
      expect(json['id'], equals('tape-1'));
      expect(json['operator'], equals('+GST'));
      expect(json['value'], equals(18.0));
      expect(json['runningTotal'], equals(118.0));
      expect(json['presetTag'], equals('18% GST'));

      final fromJson = TapeEntry.fromJson(json);
      expect(fromJson.id, equals(entry.id));
      expect(fromJson.operator, equals(entry.operator));
      expect(fromJson.value, equals(entry.value));
      expect(fromJson.runningTotal, equals(entry.runningTotal));
      expect(fromJson.presetTag, equals(entry.presetTag));
    });
  });

  group('ComparisonRow Model', () {
    test('computes discounted totals for Side A and Side B correctly', () {
      final row = ComparisonRow(
        description: 'Bulk Purchase',
        valueA: 100.0,
        qtyA: 2.0,
        discountA: 10.0, // 200 - 10% = 180
        valueB: 120.0,
        qtyB: 1.0,
        discountB: 5.0, // 120 - 5% = 114
      );

      expect(row.finalA, closeTo(180.0, 0.001));
      expect(row.finalB, closeTo(114.0, 0.001));
    });

    test('serializes and deserializes correctly', () {
      final row = ComparisonRow(
        description: 'Item comparison',
        valueA: 50.0,
        qtyA: 3.0,
        discountA: 0.0,
        valueB: 40.0,
        qtyB: 4.0,
        discountB: 15.0,
      );

      final json = row.toJson();
      final fromJson = ComparisonRow.fromJson(json);

      expect(fromJson.description, equals('Item comparison'));
      expect(fromJson.valueA, equals(50.0));
      expect(fromJson.qtyA, equals(3.0));
      expect(fromJson.finalA, equals(150.0));
    });
  });
}
