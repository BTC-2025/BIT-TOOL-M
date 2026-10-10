import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../features/calculator/models/cross_app_history_models.dart';
import '../api/api_exceptions.dart';
import '../models/calculator_models.dart';
import '../services/calculator_api_service.dart';
import 'auth_provider.dart';
import 'session_provider.dart';

/// Status of calculator history collection state.
enum CalculatorStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Centralized state management for Calculator:
/// - In-memory calculation tape workspace (Beta Calc)
/// - GST, Discount, Currency, Compare mode
/// - Backend-persisted sessions and tape items (Standard & Compare)
/// - Multi-account data isolation and synchronization
class CalculatorProvider extends ChangeNotifier {
  final CalculatorApiService _apiService;
  final SessionProvider? sessionProvider;

  // --- Workspace: Tape state ---
  final List<TapeEntry> _tapeEntries = [];
  String _currentInput = '0';
  String _pendingOperator = '+'; // default operator for next entry
  double _runningTotal = 0.0;
  bool _hasBase = false;

  // --- Workspace: Mode state ---
  CalcMode _activeMode = CalcMode.gst;
  CurrencyType _currencyType = CurrencyType.inr;
  bool _showScientific = false;

  // --- Workspace: Set Base ---
  String _setBaseValue = '0';

  // --- Workspace: Price Comparison ---
  final List<ComparisonRow> _comparisonRows = [];
  final List<String> _comparisonSides = ['A', 'B'];

  // --- Currency conversion rate ---
  final double _simulatedUsdRate = 83.0;

  // --- Legacy / display fields ---
  String _display = '0';
  String _equation = '';
  final List<String> _history = [];
  final List<HistorySection> _historySections = [];

  // --- API State: Sessions & Compare ---
  CalculatorStatus _status = CalculatorStatus.initial;
  List<CalculatorSession> _sessions = [];
  List<CalculatorSession> _allSessions = [];
  List<CompareSession> _compareSessions = [];
  String? _errorMessage;
  bool _isSavingTape = false;
  bool _isSavingCompare = false;
  bool _isDeleting = false;

  // Monotonic counters to discard stale async responses
  int _activeHistoryRequestId = 0;
  int _activeCompareRequestId = 0;

  // Account tracking for multi-account isolation
  String? _currentUserId;
  AuthProvider? _authProvider;

  // In-flight request deduplication
  Future<void>? _pendingHistoryFetch;
  Future<void>? _pendingCompareFetch;

  CalculatorProvider([
    this.sessionProvider,
    CalculatorApiService? apiService,
    AuthProvider? authProvider,
    List<CalculatorSession>? initialSessions,
  ]) : _apiService = apiService ?? CalculatorApiService() {
    if (initialSessions != null) {
      _sessions = List.from(initialSessions);
      _allSessions = List.from(initialSessions);
      _status = CalculatorStatus.loaded;
    }
    if (authProvider != null) {
      updateAuth(authProvider);
    }
  }

  // --- Workspace Getters ---
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
  List<String> get comparisonSides => List.unmodifiable(_comparisonSides);
  double get simulatedUsdRate => _simulatedUsdRate;

  String get display => _display;
  String get equation => _equation;
  List<String> get history => List.unmodifiable(_history);
  List<HistorySection> get historySections =>
      List.unmodifiable(_historySections);

  // --- API Getters ---
  CalculatorStatus get status => _status;
  List<CalculatorSession> get sessions => List.unmodifiable(_sessions);
  List<CalculatorSession> get allSessions => List.unmodifiable(_allSessions);
  List<CompareSession> get compareSessions =>
      List.unmodifiable(_compareSessions);
  String? get errorMessage => _errorMessage;
  bool get isLoadingHistory => _status == CalculatorStatus.loading;
  bool get hasHistoryError => _status == CalculatorStatus.error;
  bool get isHistoryLoaded => _status == CalculatorStatus.loaded;
  bool get isSavingTape => _isSavingTape;
  bool get isSavingCompare => _isSavingCompare;
  bool get isDeleting => _isDeleting;

  AuthProvider? get authProvider => _authProvider;

  // ==========================================
  // Multi-Account Synchronization & Isolation
  // ==========================================

  /// Handles account switching and data isolation between users.
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    final newUserId = authProvider.user?.id.toString();

    if (!authProvider.isAuthenticated || newUserId == null) {
      if (_currentUserId != null || _sessions.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[CalculatorProvider] User signed out. Invalidating calculator state.',
          );
        }
        _invalidateState();
      }
      _currentUserId = null;
      return;
    }

    if (newUserId != _currentUserId) {
      if (kDebugMode) {
        debugPrint(
          '[CalculatorProvider] Account changed: previous=$_currentUserId -> new=$newUserId. Invalidating state and fetching history.',
        );
      }
      _invalidateState();
      _currentUserId = newUserId;
      fetchHistory(forceRefresh: true);
      fetchCompareHistory(forceRefresh: true);
    }
  }

  void _invalidateState() {
    _activeHistoryRequestId++;
    _activeCompareRequestId++;
    _pendingHistoryFetch = null;
    _pendingCompareFetch = null;
    _sessions = [];
    _allSessions = [];
    _compareSessions = [];
    _historySections.clear();
    _history.clear();
    _status = CalculatorStatus.initial;
    _errorMessage = null;
    _isSavingTape = false;
    _isDeleting = false;
    notifyListeners();
  }

  // ==========================================
  // Cross-App Grouping (Derived from API Data)
  // ==========================================

  /// Derives cross-app items and counts strictly from API-persisted sessions.
  ///
  /// Guarantees that BNX Mail, Bit Tool, Cliks, and Cliks Business
  /// reflect real session counts with zero fabricated records.
  List<CrossAppItem> get crossAppItems {
    final Map<String, List<CrossAppTape>> appTapesMap = {
      'bnx_mail': [],
      'bit_tool': [],
      'cliks': [],
      'cliks_business': [],
    };

    final Map<String, String> appNameMap = {
      'bnx_mail': 'BNX Mail',
      'bit_tool': 'Bit Tool',
      'cliks': 'Cliks',
      'cliks_business': 'Cliks Business',
    };

    final source = _allSessions.isNotEmpty ? _allSessions : _sessions;
    for (final session in source) {
      final appKey = _normalizeAppKey(session.applicationName, session.title);
      final tape = session.toCrossAppTape();

      if (appTapesMap.containsKey(appKey)) {
        appTapesMap[appKey]!.add(tape);
      } else {
        // Dynamic app returned by backend
        appTapesMap[appKey] = [tape];
        appNameMap[appKey] = session.applicationName.isNotEmpty
            ? session.applicationName
            : appKey;
      }
    }

    // Sort tapes descending by date
    for (final tapes in appTapesMap.values) {
      tapes.sort((a, b) => b.id.compareTo(a.id));
    }

    // Build the ordered items list
    final List<CrossAppItem> items = [];
    final standardKeys = ['bnx_mail', 'bit_tool', 'cliks', 'cliks_business'];

    for (final key in standardKeys) {
      items.add(
        CrossAppItem(
          id: key,
          name: appNameMap[key]!,
          iconKey: key,
          tapes: appTapesMap[key]!,
        ),
      );
    }

    // Add any non-standard apps that the API may have returned
    appTapesMap.forEach((key, tapes) {
      if (!standardKeys.contains(key)) {
        items.add(
          CrossAppItem(
            id: key,
            name: appNameMap[key] ?? key,
            iconKey: key,
            tapes: tapes,
          ),
        );
      }
    });

    return List.unmodifiable(items);
  }

  String _normalizeAppKey(String appName, String title) {
    final lowerApp = appName.trim().toLowerCase();
    final lowerTitle = title.trim().toLowerCase();

    if (lowerApp.contains('bnx') || lowerTitle.contains('bnx mail') || lowerTitle.contains('[bnx mail]')) {
      return 'bnx_mail';
    }
    if (lowerApp.contains('cliks business') || lowerTitle.contains('cliks business') || lowerTitle.contains('[cliks business]')) {
      return 'cliks_business';
    }
    if (lowerApp.contains('cliks') || lowerTitle.contains('cliks') || lowerTitle.contains('[cliks]')) {
      return 'cliks';
    }
    return 'bit_tool';
  }

  // ==========================================
  // Standard Calculator History API Operations
  // ==========================================

  /// Fetches saved calculator history from GET /history.
  Future<void> fetchHistory({bool forceRefresh = false}) {
    if (!forceRefresh && _pendingHistoryFetch != null) {
      return _pendingHistoryFetch!;
    }
    _pendingHistoryFetch = _executeFetchHistory();
    return _pendingHistoryFetch!;
  }

  Future<void> _executeFetchHistory() async {
    final requestId = ++_activeHistoryRequestId;
    _status = CalculatorStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getHistory().catchError((e) {
          if (kDebugMode) {
            debugPrint('[CalculatorProvider] getHistory error: $e');
          }
          return <CalculatorSession>[];
        }),
        _apiService.getHistoryAll().catchError((e) {
          if (kDebugMode) {
            debugPrint('[CalculatorProvider] getHistoryAll error: $e');
          }
          return <CalculatorSession>[];
        }),
      ]);
      if (requestId != _activeHistoryRequestId) return;

      final standard = results[0];
      final all = results[1];

      final mergedMap = <String, CalculatorSession>{};
      for (final s in standard) {
        mergedMap[s.id] = s;
      }
      for (final s in all) {
        mergedMap[s.id] = s;
      }

      _sessions = standard.isNotEmpty ? standard : (all.isNotEmpty ? all : []);
      _allSessions = mergedMap.values.toList();

      _status = CalculatorStatus.loaded;
      notifyListeners();
    } catch (e) {
      if (requestId != _activeHistoryRequestId) return;
      _status = CalculatorStatus.error;
      _errorMessage = _resolveErrorMessage(e);
      notifyListeners();
    } finally {
      _pendingHistoryFetch = null;
    }
  }

  /// Fetches details for a specific session by ID (GET /sessions/:id).
  Future<CalculatorSession> fetchSessionDetails(String id) async {
    try {
      final session = await _apiService.getSessionById(id);
      final index = _sessions.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sessions[index] = session;
        notifyListeners();
      }
      return session;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalculatorProvider] Error fetching session details $id: $e');
      }
      rethrow;
    }
  }

  /// Saves the current workspace tape entries as a persistent session (POST /sessions).
  Future<CalculatorSession?> saveTapeSession({
    String? title,
    String? applicationName,
  }) async {
    if (_tapeEntries.isEmpty) return null;

    _isSavingTape = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final defaultTitle = 'Tape - $timeStr';
      final finalTitle = title?.trim().isNotEmpty == true ? title!.trim() : defaultTitle;
      final finalAppName = applicationName ?? 'Bit Tool';

      // 1. Create the session
      final createdSession = await _apiService.createSession(
        title: finalTitle,
        mode: _activeMode == CalcMode.gst ? 'business' : 'standard',
        currency: _currencyType == CurrencyType.usd ? 'USD' : 'INR',
        applicationName: finalAppName,
      );

      // 2. Add each tape item
      final savedItems = <CalculatorTapeItem>[];
      for (int i = 0; i < _tapeEntries.length; i++) {
        final entry = _tapeEntries[i];
        final op = (entry.operator == '=' || entry.operator.isEmpty) ? '+' : entry.operator;
        final savedItem = await _apiService.addSessionItem(
          sessionId: createdSession.id,
          sequence: i + 1,
          value: entry.value,
          operator: op,
          runningTotal: entry.runningTotal,
          label: entry.label ?? entry.presetTag ?? '',
        );
        savedItems.add(savedItem);
      }

      final fullSession = createdSession.copyWith(
        items: savedItems,
        itemCount: savedItems.length,
        totalAmount: _runningTotal,
      );

      _sessions.insert(0, fullSession);

      sessionProvider?.logActivity(
        iconName: 'calculate',
        device: 'Current Device',
        module: 'Calculator',
        duration: '220ms',
        status: 'Success',
        description: 'Saved tape session: "$finalTitle"',
        category: 'Calculator',
      );

      return fullSession;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalculatorProvider] Failed to save tape session: $e');
      }
      rethrow;
    } finally {
      _isSavingTape = false;
      notifyListeners();
    }
  }

  /// Loads saved cross-app tape into the active calculator workspace.
  void loadFromCrossAppTape(CrossAppTape tape) {
    clearAll();
    if (tape.steps.isEmpty) return;

    for (int i = 0; i < tape.steps.length; i++) {
      final step = tape.steps[i];
      final isBase = i == 0;
      if (isBase) {
        _runningTotal = step.value;
        _hasBase = true;
        _tapeEntries.add(
          TapeEntry(
            id: step.id.isNotEmpty
                ? step.id
                : DateTime.now().millisecondsSinceEpoch.toString(),
            operator: step.operator.isNotEmpty ? step.operator : '=',
            value: step.value,
            runningTotal: step.runningTotal != 0.0 ? step.runningTotal : step.value,
            isBase: true,
            label: step.label,
          ),
        );
      } else {
        _tapeEntries.add(
          TapeEntry(
            id: step.id.isNotEmpty
                ? step.id
                : '${DateTime.now().millisecondsSinceEpoch}_$i',
            operator: step.operator.isNotEmpty ? step.operator : '+',
            value: step.value,
            runningTotal: step.runningTotal,
            isBase: false,
            label: step.label,
          ),
        );
      }
    }
    _runningTotal = tape.totalAmount != 0.0
        ? tape.totalAmount
        : (_tapeEntries.isNotEmpty ? _tapeEntries.last.runningTotal : 0.0);
    _display = _formatNumber(_runningTotal);
    notifyListeners();
  }

  /// Deletes a calculator session (DELETE /sessions/:id).
  Future<void> deleteSession(String id) async {
    _isDeleting = true;
    notifyListeners();

    try {
      await _apiService.deleteSession(id);
      _sessions.removeWhere((s) => s.id == id);
      _allSessions.removeWhere((s) => s.id == id);

      sessionProvider?.logActivity(
        iconName: 'delete',
        device: 'Current Device',
        module: 'Calculator',
        duration: '150ms',
        status: 'Success',
        description: 'Deleted calculator session $id',
        category: 'Calculator',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalculatorProvider] Failed to delete session $id: $e');
      }
      rethrow;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Clears all standard calculator sessions (DELETE /sessions).
  Future<void> clearAllSessions() async {
    _isDeleting = true;
    notifyListeners();

    try {
      await _apiService.clearAllSessions();
      _sessions.clear();
      _allSessions.clear();

      sessionProvider?.logActivity(
        iconName: 'delete_sweep',
        device: 'Current Device',
        module: 'Calculator',
        duration: '200ms',
        status: 'Success',
        description: 'Cleared all calculator history sessions',
        category: 'Calculator',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalculatorProvider] Failed to clear all sessions: $e');
      }
      rethrow;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ==========================================
  // Compare Mode History API Operations
  // ==========================================

  /// Fetches comparison history from GET /compare/history.
  Future<void> fetchCompareHistory({bool forceRefresh = false}) {
    if (!forceRefresh && _pendingCompareFetch != null) {
      return _pendingCompareFetch!;
    }
    _pendingCompareFetch = _executeFetchCompareHistory();
    return _pendingCompareFetch!;
  }

  Future<void> _executeFetchCompareHistory() async {
    final requestId = ++_activeCompareRequestId;
    try {
      final fetched = await _apiService.getCompareHistory();
      if (requestId != _activeCompareRequestId) return;
      _compareSessions = fetched;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalculatorProvider] Error fetching compare history: $e');
      }
    } finally {
      _pendingCompareFetch = null;
    }
  }

  /// Saves the current workspace comparison rows as a compare session (POST /compare/sessions).
  Future<CompareSession?> saveCompareSession({String? title}) async {
    if (_comparisonRows.isEmpty) return null;

    _isSavingCompare = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final finalTitle = title?.trim().isNotEmpty == true
          ? title!.trim()
          : 'Comparison - $timeStr';

      final created = await _apiService.createCompareSession(
        title: finalTitle,
        mode: 'compare',
        currency: _currencyType == CurrencyType.usd ? 'USD' : 'INR',
      );

      final savedItems = <CompareItem>[];
      for (int i = 0; i < _comparisonRows.length; i++) {
        final row = _comparisonRows[i];
        final item = await _apiService.addCompareItem(
          sessionId: created.id,
          description: row.description,
          valueA: row.valueA,
          valueB: row.valueB,
          qtyA: row.qtyA,
          qtyB: row.qtyB,
          discountA: row.discountA,
          discountB: row.discountB,
          sequence: i + 1,
        );
        savedItems.add(item);
      }

      final full = CompareSession(
        id: created.id,
        title: created.title,
        mode: created.mode,
        currency: created.currency,
        createdAt: created.createdAt,
        items: savedItems,
      );

      _compareSessions.insert(0, full);
      return full;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalculatorProvider] Failed to save compare session: $e');
      }
      rethrow;
    } finally {
      _isSavingCompare = false;
      notifyListeners();
    }
  }

  /// Formats the current calculation workspace tape into a text summary.
  String copyTapeSummary() {
    if (_activeMode == CalcMode.compare) {
      final buffer = StringBuffer('=== Compare Summary ===\n');
      for (final row in _comparisonRows) {
        buffer.writeln(
          '${row.description}: Side A = ${_formatNumber(row.finalA)}, Side B = ${_formatNumber(row.finalB)}',
        );
      }
      return buffer.toString();
    } else {
      if (_tapeEntries.isEmpty) {
        return 'Tape total: ${_formatNumber(_runningTotal)}';
      }
      final buffer = StringBuffer('=== Beta Calc Tape Summary ===\n');
      for (int i = 0; i < _tapeEntries.length; i++) {
        final e = _tapeEntries[i];
        final op = e.isBase ? '=' : e.operator;
        final label = (e.label != null && e.label!.isNotEmpty) ? ' (${e.label})' : '';
        buffer.writeln('$op ${_formatNumber(e.value)}$label = ${_formatNumber(e.runningTotal)}');
      }
      buffer.writeln('Total: ${_formatNumber(_runningTotal)}');
      return buffer.toString();
    }
  }

  /// Deletes a comparison session (DELETE /compare/sessions/:id).
  Future<void> deleteCompareSession(String id) async {
    try {
      await _apiService.deleteCompareSession(id);
      _compareSessions.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalculatorProvider] Failed to delete compare session $id: $e');
      }
      rethrow;
    }
  }

  /// Clears all compare history (DELETE /compare/history).
  Future<void> clearAllCompareHistory() async {
    try {
      await _apiService.clearCompareHistory();
      _compareSessions.clear();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalculatorProvider] Failed to clear compare history: $e');
      }
      rethrow;
    }
  }

  // ==========================================
  // Workspace Interaction: Tape Entry Logic
  // ==========================================

  void enterDigit(String char) {
    if (char == '.') {
      if (_currentInput.contains('.')) return;
      if (_currentInput.isEmpty || _currentInput == '0') {
        _currentInput = '0.';
      } else {
        _currentInput += '.';
      }
    } else {
      if (_currentInput == '0') {
        _currentInput = char;
      } else {
        if (_currentInput.replaceAll('.', '').length >= 12) return;
        _currentInput += char;
      }
    }
    _display = _currentInput;
    notifyListeners();
  }

  void setOperator(String op) {
    if (_currentInput != '0' && _currentInput.isNotEmpty) {
      commitEntry();
    }
    _pendingOperator = op;
    notifyListeners();
  }

  void commitEntry() {
    final value = double.tryParse(_currentInput);
    if (value == null) return;

    if (!_hasBase) {
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
      sessionProvider?.logActivity(
        iconName: 'calculate',
        device: 'Current Device',
        module: 'Calculator',
        duration: '150ms',
        status: 'Success',
        description: 'Beta Calc: Set base amount to ${_formatNumber(value)}',
        category: 'Utility',
      );
    } else {
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
      sessionProvider?.logActivity(
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

    _history.insert(
      0,
      '$_pendingOperator $_currentInput = ${_formatNumber(_runningTotal)}',
    );

    _currentInput = '0';
    _pendingOperator = '+';
    _display = '0';
    _equation = '';

    saveCurrentToHistory();
    notifyListeners();
  }

  void setBaseFromField() {
    final value = double.tryParse(_setBaseValue);
    if (value == null || value == 0) return;

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
    notifyListeners();
  }

  void updateSetBaseValue(String val) {
    _setBaseValue = val;
    notifyListeners();
  }

  void clearAll() {
    saveCurrentToHistory();

    _tapeEntries.clear();
    _currentInput = '0';
    _pendingOperator = '+';
    _runningTotal = 0.0;
    _hasBase = false;
    _setBaseValue = '0';
    _display = '0';
    _equation = '';
    _comparisonRows.clear();

    notifyListeners();
  }

  void clear() {
    _currentInput = '0';
    _display = '0';
    _equation = '';
    notifyListeners();
  }

  void backspace() {
    if (_currentInput.length <= 1 || _currentInput == '0') {
      _currentInput = '0';
    } else {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
    }
    _display = _currentInput;
    notifyListeners();
  }

  void addLabel(int index, String label) {
    if (index >= 0 && index < _tapeEntries.length) {
      _tapeEntries[index].label = label.isEmpty ? null : label;
      notifyListeners();
    }
  }

  void removeTapeEntry(int index) {
    if (index >= 0 && index < _tapeEntries.length) {
      _tapeEntries.removeAt(index);
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

  void setMode(CalcMode mode) {
    _activeMode = mode;
    notifyListeners();
  }

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
    notifyListeners();
  }

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
    notifyListeners();
  }

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

  void addComparisonSide() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int i = 0; i < letters.length; i++) {
      final letter = letters[i];
      if (!_comparisonSides.contains(letter)) {
        _comparisonSides.add(letter);
        notifyListeners();
        return;
      }
    }
  }

  void removeComparisonSide(String sideKey) {
    if (_comparisonSides.length <= 2) return; // Keep minimum 2 sides
    _comparisonSides.remove(sideKey);
    for (final row in _comparisonRows) {
      row.removeSide(sideKey);
    }
    saveCurrentToHistory();
    notifyListeners();
  }

  void clearComparisonRows() {
    _comparisonRows.clear();
    saveCurrentToHistory();
    notifyListeners();
  }

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
    Map<String, double?>? sideValues,
    Map<String, double>? sideQtys,
    Map<String, double>? sideDiscounts,
  }) {
    if (index >= 0 && index < _comparisonRows.length) {
      final row = _comparisonRows[index];
      if (description != null) row.description = description;
      if (valueA != null) row.valueA = valueA;
      if (valueB != null) row.valueB = valueB;
      if (qtyA != null) row.qtyA = qtyA;
      if (qtyB != null) row.qtyB = qtyB;
      if (discountA != null) row.discountA = discountA;
      if (discountB != null) row.discountB = discountB;
      if (sideValues != null) {
        sideValues.forEach((side, val) => row.setValue(side, val));
      }
      if (sideQtys != null) {
        sideQtys.forEach((side, q) => row.setQty(side, q));
      }
      if (sideDiscounts != null) {
        sideDiscounts.forEach((side, d) => row.setDiscount(side, d));
      }
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

  void toggleScientific() {
    _showScientific = !_showScientific;
    notifyListeners();
  }

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

  void calculate() {
    if (_currentInput.contains('sin') ||
        _currentInput.contains('cos') ||
        _currentInput.contains('tan') ||
        _currentInput.contains('log') ||
        _currentInput.contains('ln') ||
        _currentInput.contains('^') ||
        _currentInput.contains('(')) {
      try {
        final result = _evaluate(_currentInput);
        if (result != 'Error') {
          _currentInput = result;
          _display = result;
          saveCurrentToHistory();
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
      commitEntry();
    }
  }

  // --- Local In-Memory History (Beta Calc) ---
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

    if (_historySections.isNotEmpty) {
      final last = _historySections.first;
      if (last.type == newSection.type &&
          last.totalValue == newSection.totalValue) {
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
      _activeMode = CalcMode.gst;
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

  // --- Helper Math Parser ---
  String _evaluate(String expr) {
    try {
      String clean = expr;
      clean = clean.replaceAll('×', '*').replaceAll('÷', '/');

      RegExp funcRegex = RegExp(r'(sin|cos|tan|log|ln)\(([^()]+)\)');
      while (funcRegex.hasMatch(clean)) {
        clean = clean.replaceAllMapped(funcRegex, (match) {
          String func = match.group(1)!;
          double val = double.parse(match.group(2)!);
          double res = 0;
          if (func == 'sin') res = sin(val * pi / 180.0);
          if (func == 'cos') res = cos(val * pi / 180.0);
          if (func == 'tan') res = tan(val * pi / 180.0);
          if (func == 'log') res = log(val) / ln10;
          if (func == 'ln') res = log(val);
          return res.toString();
        });
      }

      RegExp powerRegex = RegExp(r'(\d+(\.\d+)?)\^(\d+(\.\d+)?)');
      while (powerRegex.hasMatch(clean)) {
        clean = clean.replaceAllMapped(powerRegex, (match) {
          double base = double.parse(match.group(1)!);
          double exp = double.parse(match.group(3)!);
          return pow(base, exp).toString();
        });
      }

      List<String> tokens = [];
      String current = '';
      for (int i = 0; i < clean.length; i++) {
        String c = clean[i];
        if (['+', '-', '*', '/'].contains(c)) {
          if (current.isNotEmpty) {
            tokens.add(current);
            current = '';
          }
          tokens.add(c);
        } else {
          current += c;
        }
      }
      if (current.isNotEmpty) tokens.add(current);

      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          double a = double.parse(tokens[i - 1]);
          double b = double.parse(tokens[i + 1]);
          double r = tokens[i] == '*' ? a * b : a / b;
          tokens[i - 1] = r.toString();
          tokens.removeAt(i);
          tokens.removeAt(i);
          i--;
        }
      }

      double result = double.parse(tokens[0]);
      for (int i = 1; i < tokens.length; i += 2) {
        String op = tokens[i];
        double b = double.parse(tokens[i + 1]);
        if (op == '+') result += b;
        if (op == '-') result -= b;
      }

      return _formatNumber(result);
    } catch (e) {
      return 'Error';
    }
  }

  String _formatNumber(double val) {
    if (val.isNaN || val.isInfinite) return 'Error';
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}
