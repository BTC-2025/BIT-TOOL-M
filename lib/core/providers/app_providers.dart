import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../models/calculator_models.dart';
import 'session_provider.dart';

// --- CALENDAR PROVIDER ---
class CalendarProvider extends ChangeNotifier {
  final SessionProvider sessionProvider;
  final List<CalendarEvent> _events = [];

  CalendarProvider(this.sessionProvider) {
    _seedEvents();
  }

  List<CalendarEvent> get events => List.unmodifiable(_events);

  void addEvent(CalendarEvent event) {
    _events.add(event);
    sessionProvider.logActivity(
      iconName: 'event',
      device: 'Current Device',
      module: 'Calendar',
      duration: '310ms',
      status: 'Success',
      description: 'Created meeting: "${event.title}"',
      category: 'Calendar',
    );
    notifyListeners();
  }

  void deleteEvent(String id) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      final event = _events[index];
      _events.removeAt(index);
      sessionProvider.logActivity(
        iconName: 'event_busy',
        device: 'Current Device',
        module: 'Calendar',
        duration: '210ms',
        status: 'Success',
        description: 'Deleted meeting: "${event.title}"',
        category: 'Calendar',
      );
      notifyListeners();
    }
  }

  void _seedEvents() {
    final now = DateTime.now();
    _events.addAll([
      CalendarEvent(
        id: 'e1',
        title: 'Weekly Sync with B2Auth Dev Team',
        description:
            'Review API integration timelines for session tracking module.',
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
        isRecurring: true,
        colorHex: 'FF2196F3',
        category: 'Meeting',
        location: 'Microsoft Teams',
      ),
      CalendarEvent(
        id: 'e2',
        title: 'Project BIT Tool Architecture Review',
        description: 'Evaluate Neumorphic UI design language implementation.',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 30),
        isRecurring: false,
        colorHex: 'FF9C27B0',
        category: 'Meeting',
        location: 'Room 404 (Main Office)',
      ),
      CalendarEvent(
        id: 'e3',
        title: 'Alice\'s Birthday Celebration',
        description: 'Bring cake to the cafeteria.',
        startTime: DateTime(now.year, now.month, now.day + 1, 12, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 13, 0),
        isRecurring: false,
        colorHex: 'FFE91E63',
        category: 'Birthday',
        location: 'Cafeteria',
      ),
    ]);

    // Seed Government & Regional Holidays for 2000 to 2035
    for (int yr = 2000; yr <= 2035; yr++) {
      _events.addAll([
        CalendarEvent(
          id: 'gov_h1_$yr',
          title: 'New Year\'s Day',
          description:
              'Official Government Holiday welcoming the new calendar year.',
          startTime: DateTime(yr, 1, 1, 9, 0),
          endTime: DateTime(yr, 1, 1, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'National',
        ),
        CalendarEvent(
          id: 'gov_h_pongal_$yr',
          title: 'Pongal / Makar Sankranti',
          description: 'Harvest festival celebrated in South India.',
          startTime: DateTime(yr, 1, 14, 9, 0),
          endTime: DateTime(yr, 1, 14, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'Regional',
        ),
        CalendarEvent(
          id: 'gov_h2_$yr',
          title: 'Republic Day',
          description:
              'Commemorating the adoption of the Constitution of India in 1950.',
          startTime: DateTime(yr, 1, 26, 9, 0),
          endTime: DateTime(yr, 1, 26, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'National',
        ),
        CalendarEvent(
          id: 'gov_h_holi_$yr',
          title: 'Holi',
          description: 'Festival of colors, marking the arrival of spring.',
          startTime: DateTime(yr, 3, 25, 9, 0),
          endTime: DateTime(yr, 3, 25, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'National',
        ),
        CalendarEvent(
          id: 'gov_h3_$yr',
          title: 'Ambedkar Jayanti',
          description:
              'Celebrating the birth anniversary of Dr. B.R. Ambedkar.',
          startTime: DateTime(yr, 4, 14, 9, 0),
          endTime: DateTime(yr, 4, 14, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'National',
        ),
        CalendarEvent(
          id: 'gov_h4_$yr',
          title: 'Independence Day',
          description: 'Celebrating freedom from British rule in 1947.',
          startTime: DateTime(yr, 8, 15, 9, 0),
          endTime: DateTime(yr, 8, 15, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'National',
        ),
        CalendarEvent(
          id: 'gov_h5_$yr',
          title: 'Gandhi Jayanti',
          description:
              'Observing the birthday of Mahatma Gandhi, leader of the nation.',
          startTime: DateTime(yr, 10, 2, 9, 0),
          endTime: DateTime(yr, 10, 2, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'National',
        ),
        CalendarEvent(
          id: 'gov_h_columbus_$yr',
          title: 'Columbus Day',
          description:
              'Observance commemorating the history and exploration.',
          startTime: DateTime(yr, 10, 12, 9, 0),
          endTime: DateTime(yr, 10, 12, 17, 0),
          isRecurring: false,
          colorHex: 'FF10B981',
          category: 'Holiday',
          location: 'International',
        ),
        CalendarEvent(
          id: 'gov_h_diwali_$yr',
          title: 'Diwali',
          description:
              'Festival of lights, signifying victory of light over darkness.',
          startTime: DateTime(yr, 11, 1, 9, 0),
          endTime: DateTime(yr, 11, 1, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'National',
        ),
        CalendarEvent(
          id: 'gov_h6_$yr',
          title: 'Christmas Day',
          description:
              'Annual festival commemorating the birth of Jesus Christ.',
          startTime: DateTime(yr, 12, 25, 9, 0),
          endTime: DateTime(yr, 12, 25, 17, 0),
          isRecurring: false,
          colorHex: 'FFFF9800',
          category: 'Holiday',
          location: 'Global',
        ),
      ]);
    }
  }
}

// --- CALCULATOR PROVIDER (BETA CALC) ---
class CalculatorProvider extends ChangeNotifier {
  final SessionProvider sessionProvider;

  // --- Tape state ---
  final List<TapeEntry> _tapeEntries = [];
  String _currentInput = '0';
  String _pendingOperator = '+'; // default operator for next entry
  double _runningTotal = 0.0;
  bool _hasBase = false;

  // --- Mode state ---
  CalcMode _activeMode = CalcMode.gst;
  CurrencyType _currencyType = CurrencyType.inr;
  bool _showScientific = false;

  // --- Set Base ---
  String _setBaseValue = '0';

  // --- Price Comparison ---
  final List<ComparisonRow> _comparisonRows = [];

  // --- Currency ---
  final double _simulatedUsdRate = 83.0;

  // --- Legacy fields for backward compatibility ---
  String _display = '0';
  String _equation = '';
  final List<String> _history = [];

  CalculatorProvider(this.sessionProvider);

  // --- Getters ---
  List<TapeEntry> get tapeEntries => List.unmodifiable(_tapeEntries);
  String get currentInput => _currentInput;
  String get pendingOperator => _pendingOperator;
  double get runningTotal => _runningTotal;
  bool get hasBase => _hasBase;
  CalcMode get activeMode => _activeMode;
  CurrencyType get currencyType => _currencyType;
  bool get showScientific => _showScientific;
  String get setBaseValue => _setBaseValue;
  List<ComparisonRow> get comparisonRows => List.unmodifiable(_comparisonRows);
  double get simulatedUsdRate => _simulatedUsdRate;

  // Legacy getters
  String get display => _display;
  String get equation => _equation;
  List<String> get history => _history;

  // --- Digit / decimal entry ---
  void enterDigit(String char) {
    if (char == '.') {
      if (_currentInput.contains('.')) return; // prevent duplicate decimal
      if (_currentInput.isEmpty || _currentInput == '0') {
        _currentInput = '0.';
      } else {
        _currentInput += '.';
      }
    } else {
      if (_currentInput == '0') {
        _currentInput = char;
      } else {
        if (_currentInput.replaceAll('.', '').length >= 12) {
          return; // digit limit
        }
        _currentInput += char;
      }
    }
    _display = _currentInput;
    notifyListeners();
  }

  // --- Set pending operator ---
  void setOperator(String op) {
    // If the user has entered some digits, commit them automatically or switch operator
    if (_currentInput != '0' && _currentInput.isNotEmpty) {
      commitEntry();
    }
    _pendingOperator = op;
    notifyListeners();
  }

  // --- Commit entry (= button) ---
  void commitEntry() {
    final value = double.tryParse(_currentInput);
    if (value == null) return;

    if (!_hasBase) {
      // First entry becomes the base amount
      _runningTotal = value;
      _hasBase = true;
      _tapeEntries.add(
        TapeEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          operator: '=',
          value: value,
          runningTotal: _runningTotal,
          isBase: true,
        ),
      );
      sessionProvider.logActivity(
        iconName: 'calculate',
        device: 'Current Device',
        module: 'Calculator',
        duration: '150ms',
        status: 'Success',
        description: 'Beta Calc: Set base amount to ${_formatNumber(value)}',
        category: 'Utility',
      );
    } else {
      // Subsequent entries use pending operator
      double newTotal = _runningTotal;
      if (_pendingOperator == '+') {
        newTotal = _runningTotal + value;
      } else if (_pendingOperator == '-') {
        newTotal = _runningTotal - value;
      } else if (_pendingOperator == '×' || _pendingOperator == 'x') {
        newTotal = _runningTotal * value;
      } else if (_pendingOperator == '÷' || _pendingOperator == '/') {
        if (value == 0) return;
        newTotal = _runningTotal / value;
      }
      _runningTotal = newTotal;
      _tapeEntries.add(
        TapeEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          operator: _pendingOperator,
          value: value,
          runningTotal: _runningTotal,
        ),
      );
      sessionProvider.logActivity(
        iconName: 'calculate',
        device: 'Current Device',
        module: 'Calculator',
        duration: '180ms',
        status: 'Success',
        description:
            'Beta Calc: $_pendingOperator ${_formatNumber(value)} = ${_formatNumber(_runningTotal)}',
        category: 'Utility',
      );
    }

    // Record in legacy history
    _history.insert(
      0,
      '$_pendingOperator $_currentInput = ${_formatNumber(_runningTotal)}',
    );

    // Reset input for next entry
    _currentInput = '0';
    _pendingOperator = '+';
    _display = '0';
    _equation = '';

    saveCurrentToHistory(); // Auto-save after commit
    notifyListeners();
  }

  // --- Set base from SET BASE field ---
  void setBaseFromField() {
    final value = double.tryParse(_setBaseValue);
    if (value == null || value == 0) return;

    // Clear existing tape and set new base
    _tapeEntries.clear();
    _runningTotal = value;
    _hasBase = true;
    _tapeEntries.add(
      TapeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        operator: '=',
        value: value,
        runningTotal: _runningTotal,
        isBase: true,
      ),
    );
    _setBaseValue = '0';
    _currentInput = '0';
    _pendingOperator = '+';
    sessionProvider.logActivity(
      iconName: 'calculate',
      device: 'Current Device',
      module: 'Calculator',
      duration: '150ms',
      status: 'Success',
      description: 'Beta Calc: Set base from field to ${_formatNumber(value)}',
      category: 'Utility',
    );
    notifyListeners();
  }

  void updateSetBaseValue(String val) {
    _setBaseValue = val;
    notifyListeners();
  }

  // --- Clear all (↺ reset) ---
  void clearAll() {
    // Auto-save to history before clearing
    saveCurrentToHistory();

    _tapeEntries.clear();
    _currentInput = '0';
    _pendingOperator = '+';
    _runningTotal = 0.0;
    _hasBase = false;
    _setBaseValue = '0';
    _display = '0';
    _equation = '';
    _comparisonRows.clear(); // Ensure comparisons are also cleared

    sessionProvider.logActivity(
      iconName: 'refresh',
      device: 'Current Device',
      module: 'Calculator',
      duration: '100ms',
      status: 'Success',
      description: 'Beta Calc: Tape and comparisons cleared (saved to history)',
      category: 'Utility',
    );
    notifyListeners();
  }

  // --- Clear current input only (C) ---
  void clear() {
    _currentInput = '0';
    _display = '0';
    _equation = '';
    notifyListeners();
  }

  // --- Backspace ---
  void backspace() {
    if (_currentInput.length <= 1 || _currentInput == '0') {
      _currentInput = '0';
    } else {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    }
    _display = _currentInput;
    notifyListeners();
  }

  // --- Label management ---
  void addLabel(int index, String label) {
    if (index >= 0 && index < _tapeEntries.length) {
      _tapeEntries[index].label = label.isEmpty ? null : label;
      notifyListeners();
    }
  }

  // --- History Management ---
  final List<HistorySection> _historySections = [];
  List<HistorySection> get historySections =>
      List.unmodifiable(_historySections);

  void saveCurrentToHistory() {
    HistorySection? newSection;
    if (_activeMode == CalcMode.compare) {
      if (_comparisonRows.isEmpty) return;
      newSection = HistorySection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        comparisonRows: List.from(_comparisonRows),
        type: CalculationType.comparison,
        totalValue: _comparisonRows.fold(
          0.0,
          (sum, row) => sum + row.finalA + row.finalB,
        ),
      );
    } else {
      if (_tapeEntries.isEmpty) return;
      newSection = HistorySection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        tapeEntries: List.from(_tapeEntries),
        type: CalculationType.tape,
        totalValue: _runningTotal,
      );
    }

    // Deduplication: Don't save if it's identical to the last entry
    if (_historySections.isNotEmpty) {
      final last = _historySections.first;
      if (last.type == newSection.type &&
          last.totalValue == newSection.totalValue) {
        // Further deep check could be added here if needed, but totalValue + type is a good start
        return;
      }
    }

    _historySections.insert(0, newSection);
    notifyListeners();
  }

  void restoreHistorySection(String id) {
    final section = _historySections.firstWhere((s) => s.id == id);
    if (section.type == CalculationType.comparison) {
      _comparisonRows.clear();
      _comparisonRows.addAll(List.from(section.comparisonRows!));
      _activeMode = CalcMode.compare;
    } else {
      _tapeEntries.clear();
      _tapeEntries.addAll(List.from(section.tapeEntries!));
      _runningTotal = section.totalValue;
      _hasBase = true;
      _activeMode = CalcMode.gst; // Default back to tape mode
    }
    notifyListeners();
  }

  void deleteHistorySection(String id) {
    _historySections.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  String copySectionSummary(String id) {
    final section = _historySections.firstWhere((s) => s.id == id);
    final buffer = StringBuffer();
    buffer.writeln('# BETA CALC LOG — ${section.timestamp}');
    buffer.writeln(
      'Type: ${section.type == CalculationType.comparison ? "Comparison" : "Calculation"}',
    );
    buffer.writeln(
      'Total: ${getCurrencySymbol()}${section.totalValue.toStringAsFixed(2)}',
    );
    buffer.writeln('------------------------');

    if (section.type == CalculationType.comparison) {
      for (var row in section.comparisonRows!) {
        buffer.writeln(
          '${row.description}: ${getCurrencySymbol()}${row.finalA.toStringAsFixed(2)} vs ${getCurrencySymbol()}${row.finalB.toStringAsFixed(2)}',
        );
      }
    } else {
      for (var entry in section.tapeEntries!) {
        final prefix = entry.isBase ? 'BASE' : entry.operator;
        buffer.writeln(
          '$prefix ${entry.value.toStringAsFixed(2)} → ${getCurrencySymbol()}${entry.runningTotal.toStringAsFixed(2)}',
        );
      }
    }
    return buffer.toString();
  }

  // --- Remove tape entry ---
  void removeTapeEntry(int index) {
    if (index >= 0 && index < _tapeEntries.length) {
      _tapeEntries.removeAt(index);
      // Recalculate running totals
      _recalculateRunningTotals();
      notifyListeners();
    }
  }

  void _recalculateRunningTotals() {
    double total = 0.0;
    _hasBase = false;
    for (int i = 0; i < _tapeEntries.length; i++) {
      final entry = _tapeEntries[i];
      if (entry.isBase || entry.operator == '=') {
        total = entry.value;
        _hasBase = true;
      } else if (entry.operator == '+') {
        total += entry.value;
      } else if (entry.operator == '-') {
        total -= entry.value;
      } else if (entry.operator == '×' || entry.operator == 'x') {
        total *= entry.value;
      } else if (entry.operator == '÷' || entry.operator == '/') {
        if (entry.value != 0) total /= entry.value;
      }
      // Update the running total in place (TapeEntry fields are final except label,
      // so we rebuild)
      _tapeEntries[i] = TapeEntry(
        id: entry.id,
        operator: entry.operator,
        value: entry.value,
        runningTotal: total,
        label: entry.label,
        isBase: entry.isBase,
        presetTag: entry.presetTag,
      );
    }
    _runningTotal = total;
    if (_tapeEntries.isEmpty) {
      _hasBase = false;
      _runningTotal = 0.0;
    }
  }

  // --- Mode switching ---
  void setMode(CalcMode mode) {
    _activeMode = mode;
    notifyListeners();
  }

  // --- GST presets ---
  void applyGstPreset(double percentage) {
    if (!_hasBase || _runningTotal == 0) return;
    final gstAmount = _runningTotal * (percentage / 100.0);
    _runningTotal += gstAmount;
    _tapeEntries.add(
      TapeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        operator: '+',
        value: gstAmount,
        runningTotal: _runningTotal,
        presetTag: '${percentage.toInt()}% GST',
      ),
    );
    sessionProvider.logActivity(
      iconName: 'calculate',
      device: 'Current Device',
      module: 'Calculator',
      duration: '150ms',
      status: 'Success',
      description:
          'Beta Calc: Applied +${percentage.toInt()}% GST (${_formatNumber(gstAmount)})',
      category: 'Utility',
    );
    notifyListeners();
  }

  // --- Discount presets ---
  void applyDiscountPreset(double percentage) {
    if (!_hasBase || _runningTotal == 0) return;
    final discountAmount = _runningTotal * (percentage / 100.0);
    _runningTotal -= discountAmount;
    _tapeEntries.add(
      TapeEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        operator: '-',
        value: discountAmount,
        runningTotal: _runningTotal,
        presetTag: '${percentage.toInt()}% Discount',
      ),
    );
    sessionProvider.logActivity(
      iconName: 'calculate',
      device: 'Current Device',
      module: 'Calculator',
      duration: '150ms',
      status: 'Success',
      description:
          'Beta Calc: Applied -${percentage.toInt()}% Discount (${_formatNumber(discountAmount)})',
      category: 'Utility',
    );
    notifyListeners();
  }

  // --- Currency toggle ---
  void toggleCurrency() {
    _currencyType = _currencyType == CurrencyType.inr
        ? CurrencyType.usd
        : CurrencyType.inr;
    notifyListeners();
  }

  void setCurrency(CurrencyType type) {
    _currencyType = type;
    notifyListeners();
  }

  double getTotalInCurrency() {
    if (_currencyType == CurrencyType.usd) {
      return _runningTotal / _simulatedUsdRate;
    }
    return _runningTotal;
  }

  String getCurrencySymbol() {
    return _currencyType == CurrencyType.usd ? '\$' : '₹';
  }

  String getFormattedTotal() {
    final total = getTotalInCurrency();
    return '${getCurrencySymbol()}${_formatNumber(total)}';
  }

  // --- Price Comparison ---
  void addComparisonRow() {
    _comparisonRows.add(ComparisonRow());
    saveCurrentToHistory();
    notifyListeners();
  }

  void updateComparisonRow(
    int index, {
    String? description,
    double? valueA,
    double? valueB,
    double? qtyA,
    double? qtyB,
    double? discountA,
    double? discountB,
  }) {
    if (index >= 0 && index < _comparisonRows.length) {
      if (description != null) _comparisonRows[index].description = description;
      if (valueA != null) _comparisonRows[index].valueA = valueA;
      if (valueB != null) _comparisonRows[index].valueB = valueB;
      if (qtyA != null) _comparisonRows[index].qtyA = qtyA;
      if (qtyB != null) _comparisonRows[index].qtyB = qtyB;
      if (discountA != null) _comparisonRows[index].discountA = discountA;
      if (discountB != null) _comparisonRows[index].discountB = discountB;
      saveCurrentToHistory();
      notifyListeners();
    }
  }

  void removeComparisonRow(int index) {
    if (index >= 0 && index < _comparisonRows.length) {
      _comparisonRows.removeAt(index);
      saveCurrentToHistory();
      notifyListeners();
    }
  }

  // --- Scientific toggle ---
  void toggleScientific() {
    _showScientific = !_showScientific;
    notifyListeners();
  }

  // --- Legacy: append for scientific mode ---
  void append(String char) {
    if (_currentInput == 'Error') {
      _currentInput = '0';
    }

    if (['sin', 'cos', 'tan', 'log', 'ln'].contains(char)) {
      if (_currentInput == '0') {
        _currentInput = '$char(';
      } else {
        _currentInput += '$char(';
      }
    } else if (char == 'π') {
      if (_currentInput == '0') {
        _currentInput = '3.1415926535';
      } else {
        _currentInput += '3.1415926535';
      }
    } else if (char == 'e') {
      if (_currentInput == '0') {
        _currentInput = '2.7182818284';
      } else {
        _currentInput += '2.7182818284';
      }
    } else if (char == '^' || char == '(' || char == ')') {
      if (_currentInput == '0' && char != '(') return;
      _currentInput += char;
    } else {
      enterDigit(char);
      return;
    }
    _display = _currentInput;
    notifyListeners();
  }

  // --- Legacy: calculate for scientific expressions ---
  void calculate() {
    if (_currentInput.contains('sin') ||
        _currentInput.contains('cos') ||
        _currentInput.contains('tan') ||
        _currentInput.contains('log') ||
        _currentInput.contains('ln') ||
        _currentInput.contains('^') ||
        _currentInput.contains('(')) {
      // Scientific expression — evaluate inline
      try {
        final result = _evaluate(_currentInput);
        if (result != 'Error') {
          _currentInput = result;
          _display = result;
          saveCurrentToHistory(); // Auto-save scientific result
        } else {
          _currentInput = 'Error';
          _display = 'Error';
        }
      } catch (e) {
        _currentInput = 'Error';
        _display = 'Error';
      }
      notifyListeners();
    } else {
      // Normal tape commit
      commitEntry();
    }
  }

  // --- Clear history ---
  void clearHistory() {
    _history.clear();
    sessionProvider.logActivity(
      iconName: 'clear_all',
      device: 'Current Device',
      module: 'Calculator',
      duration: '100ms',
      status: 'Success',
      description: 'Beta Calc: History cleared',
      category: 'Utility',
    );
    notifyListeners();
  }

  // --- Delete tape (trash icon) ---
  void deleteTape() {
    _tapeEntries.clear();
    _runningTotal = 0.0;
    _hasBase = false;
    _currentInput = '0';
    _pendingOperator = '+';
    _display = '0';
    _equation = '';
    sessionProvider.logActivity(
      iconName: 'delete',
      device: 'Current Device',
      module: 'Calculator',
      duration: '120ms',
      status: 'Success',
      description: 'Beta Calc: Tape deleted',
      category: 'Utility',
    );
    notifyListeners();
  }

  // --- Copy tape summary for sharing ---
  String copyTapeSummary() {
    final buffer = StringBuffer();
    buffer.writeln('BETA CALC — Tape Summary');
    buffer.writeln('========================');
    for (final entry in _tapeEntries) {
      final label = entry.label != null ? ' (${entry.label})' : '';
      final tag = entry.presetTag != null ? ' [${entry.presetTag}]' : '';
      final prefix = entry.isBase ? 'BASE' : entry.operator;
      buffer.writeln(
        '$prefix ${_formatNumber(entry.value)}$label$tag → ${getCurrencySymbol()}${_formatNumber(entry.runningTotal)}',
      );
    }
    buffer.writeln('------------------------');
    buffer.writeln('TOTAL: ${getFormattedTotal()}');
    return buffer.toString();
  }

  // --- Number formatting helper ---
  String _formatNumber(double value) {
    if (value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  // --- Expression evaluator (for scientific mode) ---
  String _evaluate(String input) {
    try {
      String clean = input.replaceAll('x', '*').replaceAll('÷', '/');

      // Process percentages
      clean = clean.replaceAllMapped(
        RegExp(r'(\d+\.?\d*)%'),
        (match) => '(${match.group(1)}/100)',
      );

      // Inject constants
      clean = clean.replaceAll('π', '3.1415926535');

      // 1. Process scientific functions
      clean = _evalFunctions(clean);

      // 2. Process powers
      clean = _evalPowers(clean);

      // Tokenize
      final tokens = <String>[];
      String currentNum = '';

      for (int i = 0; i < clean.length; i++) {
        final char = clean[i];
        if ('+-*/'.contains(char)) {
          if (currentNum.isNotEmpty) {
            tokens.add(currentNum);
            currentNum = '';
          }
          if (char == '-' && (tokens.isEmpty || '+-*/'.contains(tokens.last))) {
            currentNum += char;
          } else {
            tokens.add(char);
          }
        } else {
          currentNum += char;
        }
      }
      if (currentNum.isNotEmpty) {
        tokens.add(currentNum);
      }

      if (tokens.isEmpty) return '0';

      // Multiplication and Division
      final tempTokens = <String>[];
      int i = 0;
      while (i < tokens.length) {
        final token = tokens[i];
        if (token == '*' || token == '/') {
          if (tempTokens.isEmpty || i + 1 >= tokens.length) return 'Error';
          final prevNum = double.tryParse(tempTokens.removeLast());
          final nextNum = double.tryParse(tokens[i + 1]);
          if (prevNum == null || nextNum == null) return 'Error';

          double res = 0.0;
          if (token == '*') {
            res = prevNum * nextNum;
          } else {
            if (nextNum == 0) return 'Error';
            res = prevNum / nextNum;
          }
          tempTokens.add(res.toString());
          i += 2;
        } else {
          tempTokens.add(token);
          i++;
        }
      }

      if (tempTokens.isEmpty) return '0';

      // Addition and Subtraction
      double result = double.tryParse(tempTokens[0]) ?? 0.0;
      int j = 1;
      while (j < tempTokens.length) {
        final op = tempTokens[j];
        if (j + 1 >= tempTokens.length) return 'Error';
        final nextNum = double.tryParse(tempTokens[j + 1]);
        if (nextNum == null) return 'Error';

        if (op == '+') {
          result += nextNum;
        } else if (op == '-') {
          result -= nextNum;
        } else {
          return 'Error';
        }
        j += 2;
      }

      if (result.isInfinite || result.isNaN) {
        return 'Error';
      }

      double precisionResult = double.parse(result.toStringAsFixed(10));

      final formattedResult = precisionResult == precisionResult.toInt()
          ? precisionResult.toInt().toString()
          : precisionResult.toString();
      return formattedResult;
    } catch (e) {
      return 'Error';
    }
  }

  String _evalFunctions(String expr) {
    final regex = RegExp(r'(sin|cos|tan|log|ln)\(([^()]+)\)');
    int loops = 0;
    while (regex.hasMatch(expr) && loops < 5) {
      expr = expr.replaceAllMapped(regex, (match) {
        final func = match.group(1);
        final innerValStr = _evaluate(match.group(2)!);
        final innerVal = double.tryParse(innerValStr);
        if (innerVal == null) return 'Error';

        double res = 0.0;
        switch (func) {
          case 'sin':
            res = sin(innerVal * pi / 180);
            break;
          case 'cos':
            res = cos(innerVal * pi / 180);
            break;
          case 'tan':
            res = tan(innerVal * pi / 180);
            break;
          case 'ln':
            if (innerVal <= 0) return 'Error';
            res = log(innerVal);
            break;
          case 'log':
            if (innerVal <= 0) return 'Error';
            res = log(innerVal) / ln10;
            break;
        }
        return res.toString();
      });
      loops++;
    }
    return expr;
  }

  String _evalPowers(String expr) {
    final regex = RegExp(r'(\d+\.?\d*)\^(\d+\.?\d*)');
    int loops = 0;
    while (regex.hasMatch(expr) && loops < 5) {
      expr = expr.replaceAllMapped(regex, (match) {
        final base = double.tryParse(match.group(1)!);
        final exponent = double.tryParse(match.group(2)!);
        if (base == null || exponent == null) return 'Error';
        return pow(base, exponent).toString();
      });
      loops++;
    }
    return expr;
  }
}

// --- CONTACTS PROVIDER ---
class ContactsProvider extends ChangeNotifier {
  final SessionProvider sessionProvider;
  final List<ContactItem> _contacts = [];

  ContactsProvider(this.sessionProvider) {
    _seedContacts();
  }

  List<ContactItem> get contacts => List.unmodifiable(_contacts);

  void toggleFavorite(String id) {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      _contacts[index].isFavorite = !_contacts[index].isFavorite;
      sessionProvider.logActivity(
        iconName: 'favorite',
        device: 'Current Device',
        module: 'Contacts',
        duration: '100ms',
        status: 'Success',
        description: 'Toggled favorite for: ${_contacts[index].name}',
        category: 'Contacts',
      );
      notifyListeners();
    }
  }

  void toggleBlocked(String id) {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      _contacts[index].isBlocked = !_contacts[index].isBlocked;
      sessionProvider.logActivity(
        iconName: 'block',
        device: 'Current Device',
        module: 'Contacts',
        duration: '110ms',
        status: 'Success',
        description: 'Toggled block status for: ${_contacts[index].name}',
        category: 'Contacts',
      );
      notifyListeners();
    }
  }

  void addContact(ContactItem contact) {
    _contacts.add(contact);
    sessionProvider.logActivity(
      iconName: 'person_add',
      device: 'Current Device',
      module: 'Contacts',
      duration: '320ms',
      status: 'Success',
      description: 'Added new contact: "${contact.name}"',
      category: 'Contacts',
    );
    notifyListeners();
  }

  void deleteContact(String id) {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index != -1) {
      final contact = _contacts[index];
      _contacts.removeAt(index);
      sessionProvider.logActivity(
        iconName: 'person_remove',
        device: 'Current Device',
        module: 'Contacts',
        duration: '210ms',
        status: 'Success',
        description: 'Deleted contact: "${contact.name}"',
        category: 'Contacts',
      );
      notifyListeners();
    }
  }

  void _seedContacts() {
    _contacts.addAll([
      ContactItem(
        id: 'c1',
        photoUrl: '',
        name: 'virat kholi',
        company: 'Cliks Business',
        designation: 'Chithappa',
        phone: '8984724747',
        email: 'aruntest@bnxmail.com',
        department: 'Operations',
        location: 'Added 18/09/2026',
        notes: 'Cliks Business • Added 18/09/2026',
        isFavorite: true,
      ),
      ContactItem(
        id: 'c2',
        photoUrl: '',
        name: 'legal',
        company: 'Cliks Business',
        designation: 'Supplier',
        phone: '6374943436',
        email: 'vincent1182003@bnxmail.com',
        department: 'Legal',
        location: 'Added 15/09/2026',
        notes: 'Cliks Business • Added 15/09/2026',
      ),
      ContactItem(
        id: 'c3',
        photoUrl: '',
        name: 'jeni fancy 5050',
        company: 'Cliks Business',
        designation: 'Supplier',
        phone: '6374943436',
        email: 'jenifancy5050@bnxmail.com',
        department: 'Procurement',
        location: 'Added 29/08/2026',
        notes: 'Cliks Business • Added 29/08/2026',
      ),
      ContactItem(
        id: 'c4',
        photoUrl: '',
        name: 'NIIT400',
        company: 'Cliks Business',
        designation: 'Customer',
        phone: '9456161498',
        email: 'aruntest@bnxmail.com',
        department: 'Accounts',
        location: 'Added 21/08/2026',
        notes: 'Cliks Business • Added 21/08/2026',
      ),
      ContactItem(
        id: 'c5',
        photoUrl: '',
        name: 'santo',
        company: 'Cliks Business',
        designation: 'Supplier',
        phone: '6374943436',
        email: 'santhoshhhhhh@bnxmail.com',
        department: 'Logistics',
        location: 'Added 20/08/2026',
        notes: 'Cliks Business • Added 20/08/2026',
      ),
    ]);
  }
}

// --- NOTES PROVIDER ---
class NotesProvider extends ChangeNotifier {
  final SessionProvider sessionProvider;
  final List<NoteItem> _notes = [];

  NotesProvider(this.sessionProvider) {
    _seedNotes();
  }

  List<NoteItem> get notes => List.unmodifiable(_notes);

  void addNote({
    required String title,
    required String content,
    String category = 'General',
    String colorHex = '#3B82F6',
    bool isPinned = false,
  }) {
    final note = NoteItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      updatedAt: DateTime.now(),
      category: category,
      colorHex: colorHex,
      isPinned: isPinned,
    );
    _notes.insert(0, note);
    sessionProvider.logActivity(
      iconName: 'note_add',
      device: 'Current Device',
      module: 'Notes',
      duration: '180ms',
      status: 'Success',
      description: 'Created new note: "$title"',
      category: 'Notes',
    );
    notifyListeners();
  }

  void updateNote(
    String id, {
    String? title,
    String? content,
    String? category,
    String? colorHex,
    bool? isPinned,
  }) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = _notes[index];
      if (title != null) note.title = title;
      if (content != null) note.content = content;
      if (category != null) note.category = category;
      if (colorHex != null) note.colorHex = colorHex;
      if (isPinned != null) note.isPinned = isPinned;
      note.updatedAt = DateTime.now();

      sessionProvider.logActivity(
        iconName: 'edit_note',
        device: 'Current Device',
        module: 'Notes',
        duration: '120ms',
        status: 'Success',
        description: 'Updated note: "${note.title}"',
        category: 'Notes',
      );
      notifyListeners();
    }
  }

  void deleteNote(String id) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = _notes[index];
      _notes.removeAt(index);
      sessionProvider.logActivity(
        iconName: 'delete',
        device: 'Current Device',
        module: 'Notes',
        duration: '150ms',
        status: 'Success',
        description: 'Deleted note: "${note.title}"',
        category: 'Notes',
      );
      notifyListeners();
    }
  }

  void togglePin(String id) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index].isPinned = !_notes[index].isPinned;
      sessionProvider.logActivity(
        iconName: 'push_pin',
        device: 'Current Device',
        module: 'Notes',
        duration: '90ms',
        status: 'Success',
        description: 'Toggled pin for note: "${_notes[index].title}"',
        category: 'Notes',
      );
      notifyListeners();
    }
  }

  void _seedNotes() {
    final now = DateTime.now();
    _notes.addAll([
      NoteItem(
        id: 'n1',
        title: 'dfdfdfdfdfdfdfdfdfdf',
        content: 'dfsdfdfdf',
        updatedAt: now.subtract(const Duration(hours: 2)),
        category: 'Cliks',
        isPinned: true,
        colorHex: '#A7F3D0',
      ),
      NoteItem(
        id: 'n2',
        title: 'kjjkkjjkkj',
        content: 'kj jkjkjkkjkj',
        updatedAt: now.subtract(const Duration(hours: 5)),
        category: 'BNX Mail',
        isPinned: true,
        colorHex: '#FDE047',
      ),
      NoteItem(
        id: 'n3',
        title: 'lkjmlkllk',
        content: 'knnnjnjknkj',
        updatedAt: now.subtract(const Duration(days: 1)),
        category: 'Cliks Business',
        isPinned: false,
        colorHex: '#BAE6FD',
      ),
      NoteItem(
        id: 'n4',
        title: 'asdfdaadf',
        content: 'dljkdsnfdsfsda',
        updatedAt: now.subtract(const Duration(days: 2)),
        category: 'Bit Tool',
        isPinned: false,
        colorHex: '#FBCFE8',
      ),
    ]);
  }
}
