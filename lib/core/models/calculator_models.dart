/// Data models for Beta Calc — tape-style business calculator.
library;

import '../../features/calculator/models/cross_app_history_models.dart';

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
  final double
  totalValue; // Sum total for tape, or distinct value for identification

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

// ==========================================
// API Models: Sessions & Tape Items
// ==========================================

double _parseDouble(dynamic val, double fallback) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? fallback;
}

double? _tryParseDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString());
}

int _parseInt(dynamic val, int fallback) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  return int.tryParse(val.toString()) ?? fallback;
}

DateTime? _parseDateTime(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  try {
    return DateTime.parse(val.toString());
  } catch (_) {
    return null;
  }
}

/// A persisted calculator tape operation item.
class CalculatorTapeItem {
  final String id;
  final String? sessionId;
  final int sequence;
  final double value;
  final String operator;
  final double runningTotal;
  final String? label;
  final DateTime? createdAt;

  const CalculatorTapeItem({
    required this.id,
    this.sessionId,
    required this.sequence,
    required this.value,
    required this.operator,
    required this.runningTotal,
    this.label,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    if (sessionId != null) 'sessionId': sessionId,
    'sequence': sequence,
    'value': value,
    'operator': operator,
    'runningTotal': runningTotal,
    'label': label ?? '',
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory CalculatorTapeItem.fromJson(Map<String, dynamic> json) {
    return CalculatorTapeItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      sessionId:
          json['sessionId']?.toString() ?? json['session_id']?.toString(),
      sequence: _parseInt(json['sequence'] ?? json['seq'], 1),
      value: _parseDouble(json['value'], 0.0),
      operator: (json['operator'] ?? json['op'] ?? '+').toString(),
      runningTotal: _parseDouble(
        json['runningTotal'] ?? json['running_total'] ?? json['total'],
        0.0,
      ),
      label: json['label']?.toString(),
      createdAt: _parseDateTime(
        json['createdAt'] ?? json['created_at'] ?? json['timestamp'],
      ),
    );
  }

  TapeEntry toTapeEntry() {
    return TapeEntry(
      id: id,
      operator: operator,
      value: value,
      runningTotal: runningTotal,
      label: label,
      isBase: sequence == 1 || operator == '=',
    );
  }

  CrossAppTapeStep toCrossAppTapeStep({String currencyPrefix = '₹'}) {
    final dt = createdAt ?? DateTime.now();
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    final isFirst = sequence == 1 || operator == '=';
    final formattedVal = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final expr = isFirst ? '= $formattedVal' : '$operator $formattedVal';
    final res = '$currencyPrefix${runningTotal.toStringAsFixed(2)}';
    final stepLabel = (label != null && label!.trim().isNotEmpty)
        ? label!.trim()
        : (isFirst ? 'BASE VALUE' : operator);

    return CrossAppTapeStep(
      id: id,
      label: stepLabel,
      timestamp: timeStr,
      expression: expr,
      result: res,
      value: value,
      runningTotal: runningTotal,
      operator: operator,
    );
  }

  CalculatorTapeItem copyWith({
    String? id,
    String? sessionId,
    int? sequence,
    double? value,
    String? operator,
    double? runningTotal,
    String? label,
    DateTime? createdAt,
  }) {
    return CalculatorTapeItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sequence: sequence ?? this.sequence,
      value: value ?? this.value,
      operator: operator ?? this.operator,
      runningTotal: runningTotal ?? this.runningTotal,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A persisted calculator session.
class CalculatorSession {
  final String id;
  final String title;
  final String mode;
  final String currency;
  final String applicationName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? totalAmount;
  final int? itemCount;
  final List<CalculatorTapeItem> items;

  const CalculatorSession({
    required this.id,
    required this.title,
    this.mode = 'business',
    this.currency = 'INR',
    this.applicationName = 'Bit Tool',
    this.createdAt,
    this.updatedAt,
    this.totalAmount,
    this.itemCount,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'mode': mode,
    'currency': currency,
    'applicationName': applicationName,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (totalAmount != null) 'totalAmount': totalAmount,
    if (itemCount != null) 'itemCount': itemCount,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory CalculatorSession.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['tape_items'] ?? json['data'];
    final itemsList = <CalculatorTapeItem>[];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is Map) {
          try {
            itemsList.add(
              CalculatorTapeItem.fromJson(Map<String, dynamic>.from(rawItem)),
            );
          } catch (_) {}
        }
      }
      itemsList.sort((a, b) => a.sequence.compareTo(b.sequence));
    }

    final rawTitle = (json['title'] ?? 'Tape - Untitled').toString();

    String app = (json['applicationName'] ??
            json['appName'] ??
            json['app'] ??
            '')
        .toString()
        .trim();
    if (app.isEmpty) {
      final lower = rawTitle.toLowerCase();
      if (lower.contains('[bnx mail]') || lower.contains('bnx mail')) {
        app = 'BNX Mail';
      } else if (lower.contains('[cliks business]') ||
          lower.contains('cliks business')) {
        app = 'Cliks Business';
      } else if (lower.contains('[cliks]') || lower.contains('cliks')) {
        app = 'Cliks';
      } else {
        app = 'Bit Tool';
      }
    }

    final total = _parseDouble(
      json['totalAmount'] ??
          json['total_amount'] ??
          json['runningTotal'] ??
          json['total'],
      itemsList.isNotEmpty ? itemsList.last.runningTotal : 0.0,
    );

    final count = _parseInt(
      json['itemCount'] ?? json['item_count'] ?? json['count'],
      itemsList.length,
    );

    return CalculatorSession(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: rawTitle,
      mode: (json['mode'] ?? 'business').toString(),
      currency: (json['currency'] ?? 'INR').toString(),
      applicationName: app,
      createdAt: _parseDateTime(
        json['createdAt'] ?? json['created_at'] ?? json['date'],
      ),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      totalAmount: total,
      itemCount: count,
      items: itemsList,
    );
  }

  CrossAppTape toCrossAppTape({String currencySymbol = '₹'}) {
    final curPrefix = currency.toUpperCase() == 'USD' ? '\$' : '₹';
    final total = (totalAmount != null && totalAmount! > 0)
        ? totalAmount!
        : (items.isNotEmpty ? items.last.runningTotal : 0.0);
    final dt = createdAt ?? DateTime.now();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final dateStr = '$day/$month/$year $hour:$minute';

    final steps = items
        .map((i) => i.toCrossAppTapeStep(currencyPrefix: curPrefix))
        .toList();

    return CrossAppTape(
      id: id,
      title: title,
      dateString: dateStr,
      itemCount: itemCount ?? items.length,
      totalFormatted: '$curPrefix${total.toStringAsFixed(2)}',
      totalValue: total,
      steps: steps,
    );
  }

  CalculatorSession copyWith({
    String? id,
    String? title,
    String? mode,
    String? currency,
    String? applicationName,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalAmount,
    int? itemCount,
    List<CalculatorTapeItem>? items,
  }) {
    return CalculatorSession(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      currency: currency ?? this.currency,
      applicationName: applicationName ?? this.applicationName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalAmount: totalAmount ?? this.totalAmount,
      itemCount: itemCount ?? this.itemCount,
      items: items ?? this.items,
    );
  }
}

/// A comparison item in Compare Mode.
class CompareItem {
  final String id;
  final String? sessionId;
  final String description;
  final double? valueA;
  final double? valueB;
  final double qtyA;
  final double qtyB;
  final double discountA;
  final double discountB;
  final int sequence;
  final DateTime? createdAt;

  const CompareItem({
    required this.id,
    this.sessionId,
    this.description = '',
    this.valueA,
    this.valueB,
    this.qtyA = 1.0,
    this.qtyB = 1.0,
    this.discountA = 0.0,
    this.discountB = 0.0,
    this.sequence = 1,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    if (sessionId != null) 'sessionId': sessionId,
    'description': description,
    'valueA': valueA,
    'valueB': valueB,
    'qtyA': qtyA,
    'qtyB': qtyB,
    'discountA': discountA,
    'discountB': discountB,
    'sequence': sequence,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  factory CompareItem.fromJson(Map<String, dynamic> json) {
    return CompareItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      sessionId:
          json['sessionId']?.toString() ?? json['session_id']?.toString(),
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      valueA: _tryParseDouble(json['valueA'] ?? json['value_a']),
      valueB: _tryParseDouble(json['valueB'] ?? json['value_b']),
      qtyA: _parseDouble(json['qtyA'] ?? json['qty_a'], 1.0),
      qtyB: _parseDouble(json['qtyB'] ?? json['qty_b'], 1.0),
      discountA: _parseDouble(json['discountA'] ?? json['discount_a'], 0.0),
      discountB: _parseDouble(json['discountB'] ?? json['discount_b'], 0.0),
      sequence: _parseInt(json['sequence'] ?? json['seq'], 1),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  ComparisonRow toComparisonRow() {
    return ComparisonRow(
      description: description,
      valueA: valueA,
      valueB: valueB,
      qtyA: qtyA,
      qtyB: qtyB,
      discountA: discountA,
      discountB: discountB,
    );
  }

  static CompareItem fromComparisonRow(
    ComparisonRow row, {
    String id = '',
    String? sessionId,
    int sequence = 1,
  }) {
    return CompareItem(
      id: id,
      sessionId: sessionId,
      description: row.description,
      valueA: row.valueA,
      valueB: row.valueB,
      qtyA: row.qtyA,
      qtyB: row.qtyB,
      discountA: row.discountA,
      discountB: row.discountB,
      sequence: sequence,
    );
  }
}

/// A persisted comparison session.
class CompareSession {
  final String id;
  final String title;
  final String mode;
  final String currency;
  final DateTime? createdAt;
  final List<CompareItem> items;

  const CompareSession({
    required this.id,
    required this.title,
    this.mode = 'compare',
    this.currency = 'INR',
    this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'mode': mode,
    'currency': currency,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory CompareSession.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['compare_items'] ?? json['data'];
    final itemsList = <CompareItem>[];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is Map) {
          try {
            itemsList.add(
              CompareItem.fromJson(Map<String, dynamic>.from(rawItem)),
            );
          } catch (_) {}
        }
      }
      itemsList.sort((a, b) => a.sequence.compareTo(b.sequence));
    }

    return CompareSession(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? 'Comparison - Untitled').toString(),
      mode: (json['mode'] ?? 'compare').toString(),
      currency: (json['currency'] ?? 'INR').toString(),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      items: itemsList,
    );
  }

  CompareSession copyWith({
    String? id,
    String? title,
    String? mode,
    String? currency,
    DateTime? createdAt,
    List<CompareItem>? items,
  }) {
    return CompareSession(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  List<ComparisonRow> toComparisonRows() {
    return items.map((i) => i.toComparisonRow()).toList();
  }
}
