import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/calculator_models.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/calculator_provider.dart';
import 'package:bit_tools_backend/core/services/calculator_api_service.dart';
import 'package:bit_tools_backend/features/calculator/models/cross_app_history_models.dart';

class FakeCalculatorApiService implements CalculatorApiService {
  List<CalculatorSession> mockSessions = [];
  List<CompareSession> mockCompareSessions = [];
  Exception? errorToThrow;

  int getHistoryCalls = 0;
  int getHistoryAllCalls = 0;
  int createSessionCalls = 0;
  int addSessionItemCalls = 0;
  int getSessionDetailsCalls = 0;
  int deleteSessionCalls = 0;
  int clearHistoryCalls = 0;

  int getCompareHistoryCalls = 0;
  int createCompareSessionCalls = 0;
  int addCompareItemCalls = 0;
  int updateCompareItemCalls = 0;
  int deleteCompareItemCalls = 0;
  int deleteCompareSessionCalls = 0;
  int clearCompareHistoryCalls = 0;

  @override
  Future<List<CalculatorSession>> getHistory() async {
    getHistoryCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockSessions);
  }

  @override
  Future<List<CalculatorSession>> getHistoryAll() async {
    getHistoryAllCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockSessions);
  }

  @override
  Future<CalculatorSession> createSession({
    required String title,
    String mode = 'business',
    String currency = 'INR',
    String? applicationName,
  }) async {
    createSessionCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final session = CalculatorSession(
      id: 'sess-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      mode: mode,
      currency: currency,
      applicationName: applicationName ?? 'Bit Tool',
      totalAmount: 0.0,
      createdAt: DateTime.now(),
      items: [],
    );
    mockSessions.insert(0, session);
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
    if (errorToThrow != null) throw errorToThrow!;
    final item = CalculatorTapeItem(
      id: 'item-${DateTime.now().microsecondsSinceEpoch}',
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
      final updatedItems = List<CalculatorTapeItem>.from(s.items)..add(item);
      mockSessions[idx] = s.copyWith(
        items: updatedItems,
        itemCount: updatedItems.length,
        totalAmount: runningTotal,
      );
    }
    return item;
  }

  @override
  Future<CalculatorSession> getSessionDetails(String id) async {
    getSessionDetailsCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final found = mockSessions.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Session not found'),
    );
    return found;
  }

  @override
  Future<CalculatorSession> getSessionById(String id) => getSessionDetails(id);

  @override
  Future<bool> deleteSession(String id) async {
    deleteSessionCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    mockSessions.removeWhere((s) => s.id == id);
    return true;
  }

  @override
  Future<bool> clearHistory() async {
    clearHistoryCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    mockSessions.clear();
    return true;
  }

  @override
  Future<bool> clearAllSessions() => clearHistory();

  @override
  Future<List<CompareSession>> getCompareHistory() async {
    getCompareHistoryCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return List.from(mockCompareSessions);
  }

  @override
  Future<CompareSession> createCompareSession({
    required String title,
    String mode = 'compare',
    String currency = 'INR',
  }) async {
    createCompareSessionCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final session = CompareSession(
      id: 'cmp-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      mode: mode,
      currency: currency,
      createdAt: DateTime.now(),
      items: [],
    );
    mockCompareSessions.insert(0, session);
    return session;
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
    addCompareItemCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final item = CompareItem(
      id: 'cmp-item-${DateTime.now().microsecondsSinceEpoch}',
      description: description,
      valueA: valueA,
      valueB: valueB,
      qtyA: qtyA,
      qtyB: qtyB,
      discountA: discountA,
      discountB: discountB,
      sequence: sequence,
    );
    final idx = mockCompareSessions.indexWhere((s) => s.id == sessionId);
    if (idx != -1) {
      final s = mockCompareSessions[idx];
      mockCompareSessions[idx] = s.copyWith(
        items: List<CompareItem>.from(s.items)..add(item),
      );
    }
    return item;
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
    updateCompareItemCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final item = CompareItem(
      id: itemId,
      description: description ?? '',
      valueA: valueA ?? 0.0,
      valueB: valueB ?? 0.0,
      qtyA: qtyA ?? 1.0,
      qtyB: qtyB ?? 1.0,
      discountA: discountA ?? 0.0,
      discountB: discountB ?? 0.0,
    );
    final sIdx = mockCompareSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx != -1) {
      final s = mockCompareSessions[sIdx];
      final items = List<CompareItem>.from(s.items);
      final iIdx = items.indexWhere((it) => it.id == itemId);
      if (iIdx != -1) {
        items[iIdx] = item;
        mockCompareSessions[sIdx] = s.copyWith(items: items);
      }
    }
    return item;
  }

  @override
  Future<bool> deleteCompareItem({
    required String sessionId,
    required String itemId,
  }) async {
    deleteCompareItemCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final sIdx = mockCompareSessions.indexWhere((s) => s.id == sessionId);
    if (sIdx != -1) {
      final s = mockCompareSessions[sIdx];
      final items = List<CompareItem>.from(s.items)..removeWhere((it) => it.id == itemId);
      mockCompareSessions[sIdx] = s.copyWith(items: items);
    }
    return true;
  }

  @override
  Future<bool> deleteCompareSession(String id) async {
    deleteCompareSessionCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    mockCompareSessions.removeWhere((s) => s.id == id);
    return true;
  }

  @override
  Future<bool> clearCompareHistory() async {
    clearCompareHistoryCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    mockCompareSessions.clear();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _user;
  bool _isAuthenticated = false;

  @override
  UserModel? get user => _user;

  @override
  bool get isAuthenticated => _isAuthenticated;

  void testSignIn(int id, String email) {
    _user = UserModel(
      id: id,
      email: email,
      fullName: 'User $id',
    );
    _isAuthenticated = true;
    notifyListeners();
  }

  void testSignOut() {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  @override
  Future<bool> signIn({required String email, required String password}) async {
    testSignIn(1, email);
    return true;
  }

  @override
  Future<void> signOut() async {
    testSignOut();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CalculatorProvider Tests', () {
    late FakeCalculatorApiService fakeApi;
    late CalculatorProvider provider;

    setUp(() {
      fakeApi = FakeCalculatorApiService();
      provider = CalculatorProvider(null, fakeApi);
    });

    test('fetchHistory updates sessions and crossAppItems groups', () async {
      fakeApi.mockSessions = [
        CalculatorSession(
          id: 'sess-1',
          title: 'Tape - 10:00',
          applicationName: 'BNX Mail',
          totalAmount: 1500.0,
          createdAt: DateTime.now(),
          items: [
            const CalculatorTapeItem(
              id: 'it-1',
              sequence: 1,
              value: 1500.0,
              operator: '+',
              runningTotal: 1500.0,
            ),
          ],
        ),
        CalculatorSession(
          id: 'sess-2',
          title: 'Tape - 11:00',
          applicationName: 'Bit Tool',
          totalAmount: 300.0,
          createdAt: DateTime.now(),
          items: [],
        ),
      ];

      await provider.fetchHistory();

      expect(provider.sessions.length, 2);
      expect(fakeApi.getHistoryCalls, 1);

      final items = provider.crossAppItems;
      expect(items.length, 4); // 4 standard apps

      final bnxApp = items.firstWhere((i) => i.id == 'bnx_mail');
      expect(bnxApp.tapes.length, 1);
      expect(bnxApp.tapes.first.totalAmount, 1500.0);

      final bitApp = items.firstWhere((i) => i.id == 'bit_tool');
      expect(bitApp.tapes.length, 1);
      expect(bitApp.tapes.first.id, 'sess-2');

      final cliksApp = items.firstWhere((i) => i.id == 'cliks');
      expect(cliksApp.tapes.isEmpty, true);
    });

    test('Standard Lifecycle: create tape session, add items, and delete session', () async {
      // 1. Enter digits and perform calculation in workspace
      provider.enterDigit('1');
      provider.enterDigit('0');
      provider.enterDigit('0');
      provider.commitEntry(); // Base = 100

      provider.setOperator('+');
      provider.enterDigit('5');
      provider.enterDigit('0');
      provider.commitEntry(); // Running total = 150

      expect(provider.tapeEntries.length, 2);
      expect(provider.runningTotal, 150.0);

      // 2. Save tape session
      final saved = await provider.saveTapeSession(
        title: 'Tape - Test',
        applicationName: 'Bit Tool',
      );

      expect(saved, isNotNull);
      expect(fakeApi.createSessionCalls, 1);
      expect(fakeApi.addSessionItemCalls, 2);
      expect(provider.sessions.length, 1);
      expect(provider.sessions.first.totalAmount, 150.0);

      // 3. Delete session
      await provider.deleteSession(saved!.id);
      expect(fakeApi.deleteSessionCalls, 1);
      expect(provider.sessions.isEmpty, true);
    });

    test('Compare Lifecycle: create compare session and rows, save and clear', () async {
      provider.setMode(CalcMode.compare);

      provider.addComparisonRow();
      provider.updateComparisonRow(
        0,
        description: 'Keyboard',
        valueA: 2000.0,
        valueB: 2500.0,
        qtyA: 1.0,
        qtyB: 1.0,
      );

      expect(provider.comparisonRows.length, 1);

      // Save compare session
      final saved = await provider.saveCompareSession(title: 'Hardware Comparison');
      expect(saved, isNotNull);
      expect(fakeApi.createCompareSessionCalls, 1);
      expect(fakeApi.addCompareItemCalls, 1);
      expect(provider.compareSessions.length, 1);

      // Clear compare history
      await provider.clearAllCompareHistory();
      expect(fakeApi.clearCompareHistoryCalls, 1);
      expect(provider.compareSessions.isEmpty, true);
    });

    test('Multi-account isolation: switching users clears cache and fetches fresh data', () async {
      final auth = FakeAuthProvider();
      auth.testSignIn(1, 'userA@test.com');

      provider.updateAuth(auth);
      // Wait for fetch
      await Future.delayed(const Duration(milliseconds: 50));

      expect(fakeApi.getHistoryCalls, 1);

      // Populate fake sessions for user A
      fakeApi.mockSessions = [
        CalculatorSession(
          id: 'user-a-sess-1',
          title: 'Tape A',
          totalAmount: 100.0,
          createdAt: DateTime.now(),
        ),
      ];
      await provider.fetchHistory();
      expect(provider.sessions.length, 1);

      // Switch to User B
      fakeApi.mockSessions = [
        CalculatorSession(
          id: 'user-b-sess-1',
          title: 'Tape B',
          totalAmount: 999.0,
          createdAt: DateTime.now(),
        ),
      ];

      auth.testSignIn(2, 'userB@test.com');
      provider.updateAuth(auth);
      await provider.fetchHistory();

      // User A sessions should be replaced by User B sessions
      expect(provider.sessions.length, 1);
      expect(provider.sessions.first.id, 'user-b-sess-1');
      expect(provider.sessions.first.title, 'Tape B');

      // Logout clears everything
      auth.testSignOut();
      provider.updateAuth(auth);
      expect(provider.sessions.isEmpty, true);
      expect(provider.compareSessions.isEmpty, true);
    });

    test('loadFromCrossAppTape correctly restores workspace state', () {
      const tape = CrossAppTape(
        id: 'tape-123',
        title: 'Tape - 12:00',
        dateString: '12:00',
        itemCount: 2,
        totalFormatted: '₹350.00',
        totalValue: 350.0,
        steps: [
          CrossAppTapeStep(
            id: 's-1',
            operator: '=',
            value: 100.0,
            runningTotal: 100.0,
            label: 'Base',
            timestamp: '12:00:00',
            expression: '= 100',
            result: '₹100.00',
          ),
          CrossAppTapeStep(
            id: 's-2',
            operator: '+',
            value: 250.0,
            runningTotal: 350.0,
            label: 'Bonus',
            timestamp: '12:01:00',
            expression: '+ 250',
            result: '₹350.00',
          ),
        ],
      );

      provider.loadFromCrossAppTape(tape);

      expect(provider.hasBase, true);
      expect(provider.tapeEntries.length, 2);
      expect(provider.tapeEntries[0].value, 100.0);
      expect(provider.tapeEntries[0].label, 'Base');
      expect(provider.tapeEntries[1].value, 250.0);
      expect(provider.tapeEntries[1].operator, '+');
      expect(provider.runningTotal, 350.0);
      expect(provider.display, '350');
    });
  });
}
