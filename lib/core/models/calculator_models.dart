/// Data models for Beta Calc — tape-style business calculator.

/// Represents a single line on the calculation tape.
class TapeEntry {
  final String id;
  final String operator; // '=', '+', '-', '+GST', '-DISC'
  final double value;
  final double runningTotal;
  String? label;
  final bool isBase;
  final String? presetTag; // e.g., '18% GST', '10% Discount'

  TapeEntry({
    required this.id,
    required this.operator,
    required this.value,
    required this.runningTotal,
    this.label,
    this.isBase = false,
    this.presetTag,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operator': operator,
    'value': value,
    'runningTotal': runningTotal,
    'label': label,
    'isBase': isBase,
    'presetTag': presetTag,
  };

  factory TapeEntry.fromJson(Map<String, dynamic> json) => TapeEntry(
    id: json['id'],
    operator: json['operator'],
    value: json['value'],
    runningTotal: json['runningTotal'],
    label: json['label'],
    isBase: json['isBase'],
    presetTag: json['presetTag'],
  );
}

/// A row in the Price Comparison table.
class ComparisonRow {
  String description;
  double? valueA;
  double? valueB;
  double qtyA;
  double qtyB;
  double discountA; // Percentage discount for Side A
  double discountB; // Percentage discount for Side B

  ComparisonRow({
    this.description = '',
    this.valueA,
    this.valueB,
    this.qtyA = 1.0,
    this.qtyB = 1.0,
    this.discountA = 0.0,
    this.discountB = 0.0,
  });

  double get finalA {
    final base = (valueA ?? 0.0) * qtyA;
    return base - (base * (discountA / 100.0));
  }

  double get finalB {
    final base = (valueB ?? 0.0) * qtyB;
    return base - (base * (discountB / 100.0));
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'valueA': valueA,
    'valueB': valueB,
    'qtyA': qtyA,
    'qtyB': qtyB,
    'discountA': discountA,
    'discountB': discountB,
  };

  factory ComparisonRow.fromJson(Map<String, dynamic> json) => ComparisonRow(
    description: json['description'],
    valueA: json['valueA'],
    valueB: json['valueB'],
    qtyA: json['qtyA'],
    qtyB: json['qtyB'],
    discountA: json['discountA'],
    discountB: json['discountB'],
  );
}

/// A section in the history representing a saved calculation or comparison.
class HistorySection {
  final String id;
  final DateTime timestamp;
  final List<TapeEntry>? tapeEntries;
  final List<ComparisonRow>? comparisonRows;
  final CalculationType type;
  final double totalValue; // Sum total for tape, or distinct value for identification

  HistorySection({
    required this.id,
    required this.timestamp,
    this.tapeEntries,
    this.comparisonRows,
    required this.type,
    required this.totalValue,
  });
}

enum CalculationType { tape, comparison }

/// Active mode tab for the calculator.
enum CalcMode { gst, discount, currency, compare }

/// Currency type for display.
enum CurrencyType { inr, usd }
