import 'package:flutter/foundation.dart';
import '../api/api_exceptions.dart';
import '../models/calendar_models.dart';
import '../services/calendar_api_service.dart';
import 'auth_provider.dart';
import 'session_provider.dart';

/// Status of calendar collection state.
enum CalendarStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Centralized state management for Calendar events, categories, reminders,
/// date-linked notes, global search, and account-specific isolation.
class CalendarProvider extends ChangeNotifier {
  final CalendarApiService _apiService;
  final SessionProvider? sessionProvider;

  CalendarStatus _status = CalendarStatus.initial;
  List<CalendarEvent> _events = [];
  List<CalendarCategory> _categories = [];
  List<CalendarReminder> _selectedDateReminders = [];
  List<CalendarDateNote> _selectedDateNotes = [];

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  String? _errorMessage;
  bool _isSubmitting = false;

  // Search state
  String _searchQuery = '';
  CalendarSearchResult? _searchResults;
  bool _isSearching = false;
  String? _searchError;

  // Monotonic request counter for stale request protection
  int _activeRequestId = 0;

  // Active user ID tracking
  String? _currentUserId;
  AuthProvider? _authProvider;

  // Pending mutation IDs
  final Set<String> _pendingDeleteIds = {};
  final Set<String> _pendingCompleteIds = {};

  // In-flight fetch deduplication
  Future<void>? _pendingInitialFetch;
  Future<void>? _pendingMonthFetch;

  CalendarProvider([
    this.sessionProvider,
    CalendarApiService? apiService,
    AuthProvider? authProvider,
    List<CalendarEvent>? initialEvents,
  ]) : _apiService = apiService ?? CalendarApiService() {
    if (initialEvents != null && initialEvents.isNotEmpty) {
      _events = List.from(initialEvents);
      _status = CalendarStatus.loaded;
    }
    if (authProvider != null) {
      updateAuth(authProvider);
    }
  }

  // --- Getters ---

  CalendarStatus get status => _status;
  List<CalendarEvent> get events => List.unmodifiable(_events);
  List<CalendarCategory> get categories => List.unmodifiable(_categories);
  List<CalendarReminder> get selectedDateReminders =>
      List.unmodifiable(_selectedDateReminders);
  List<CalendarDateNote> get selectedDateNotes =>
      List.unmodifiable(_selectedDateNotes);

  DateTime get currentMonth => _currentMonth;
  DateTime get selectedDate => _selectedDate;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CalendarStatus.loading;
  bool get hasError => _status == CalendarStatus.error;
  bool get isLoaded => _status == CalendarStatus.loaded;
  bool get isSubmitting => _isSubmitting;

  String get searchQuery => _searchQuery;
  CalendarSearchResult? get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;

  AuthProvider? get authProvider => _authProvider;

  bool isDeleting(String id) => _pendingDeleteIds.contains(id);
  bool isCompleting(String id) => _pendingCompleteIds.contains(id);

  /// Helper to format date as YYYY-MM-DD.
  static String formatDate(DateTime d) {
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // --- Multi-Account Synchronization ---

  /// Handles account switching and data isolation.
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;
    final newUserId = authProvider.user?.id.toString();

    if (!authProvider.isAuthenticated || newUserId == null) {
      if (_currentUserId != null || _events.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[CalendarProvider] User signed out. Invalidating calendar state.',
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
          '[CalendarProvider] Account changed: previous=$_currentUserId -> new=$newUserId. Invalidating state and fetching fresh data.',
        );
      }
      _invalidateState();
      _currentUserId = newUserId;
      fetchInitialData();
    }
  }

  void _invalidateState() {
    _activeRequestId++;
    _pendingInitialFetch = null;
    _pendingMonthFetch = null;
    _events = [];
    _categories = [];
    _selectedDateReminders = [];
    _selectedDateNotes = [];
    _searchResults = null;
    _searchQuery = '';
    _status = CalendarStatus.initial;
    _errorMessage = null;
    _isSubmitting = false;
    _isSearching = false;
    _pendingDeleteIds.clear();
    _pendingCompleteIds.clear();
    notifyListeners();
  }

  // --- Initial Data & Navigation ---

  /// Explicitly refreshes the calendar (categories, month events, selected date items).
  Future<void> refresh() async {
    await fetchInitialData(forceRefresh: true);
  }

  /// Loads categories, month events, and selected date reminders & notes.
  Future<void> fetchInitialData({bool forceRefresh = false}) {
    if (!forceRefresh && _pendingInitialFetch != null) {
      return _pendingInitialFetch!;
    }
    _pendingInitialFetch = _executeFetchInitialData();
    return _pendingInitialFetch!;
  }

  Future<void> _executeFetchInitialData() async {
    final requestId = ++_activeRequestId;
    _status = CalendarStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final catsFuture = _apiService.getCategories();
      final eventsFuture = _apiService.getMonthEvents(
        year: _currentMonth.year,
        month: _currentMonth.month,
      );
      final remindersFuture =
          _apiService.getReminders(formatDate(_selectedDate));
      final notesFuture = _apiService.getDateNotes(formatDate(_selectedDate));

      final results = await Future.wait([
        catsFuture,
        eventsFuture,
        remindersFuture,
        notesFuture,
      ]);

      if (requestId != _activeRequestId) return;

      _categories = results[0] as List<CalendarCategory>;
      _events = results[1] as List<CalendarEvent>;
      _selectedDateReminders = results[2] as List<CalendarReminder>;
      _selectedDateNotes = results[3] as List<CalendarDateNote>;

      _status = CalendarStatus.loaded;
      notifyListeners();
    } catch (e) {
      if (requestId != _activeRequestId) return;
      _status = CalendarStatus.error;
      _errorMessage = _resolveErrorMessage(e);
      notifyListeners();
    } finally {
      _pendingInitialFetch = null;
    }
  }

  /// Sets current month and fetches its events.
  Future<void> setMonth(DateTime month) async {
    final newMonth = DateTime(month.year, month.month, 1);
    if (_currentMonth.year == newMonth.year &&
        _currentMonth.month == newMonth.month) {
      return;
    }
    _currentMonth = newMonth;
    notifyListeners();
    await fetchMonthEvents();
  }

  Future<void> previousMonth() async {
    await setMonth(DateTime(_currentMonth.year, _currentMonth.month - 1, 1));
  }

  Future<void> nextMonth() async {
    await setMonth(DateTime(_currentMonth.year, _currentMonth.month + 1, 1));
  }

  Future<void> goToToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final monthChanged = _currentMonth.year != monthStart.year ||
        _currentMonth.month != monthStart.month;
    _currentMonth = monthStart;
    _selectedDate = today;
    notifyListeners();

    if (monthChanged) {
      await fetchMonthEvents();
    }
    await fetchSelectedDateItems();
  }

  /// Selects a date and loads its reminders and notes.
  Future<void> selectDate(DateTime date) async {
    final newDate = DateTime(date.year, date.month, date.day);
    if (_selectedDate == newDate) return;

    final monthChanged = _currentMonth.year != newDate.year ||
        _currentMonth.month != newDate.month;

    _selectedDate = newDate;
    if (monthChanged) {
      _currentMonth = DateTime(newDate.year, newDate.month, 1);
    }
    notifyListeners();

    if (monthChanged) {
      await fetchMonthEvents();
    }
    await fetchSelectedDateItems();
  }

  // --- Fetching Methods ---

  /// Fetches events for the currently active month with request deduplication.
  Future<void> fetchMonthEvents({bool forceRefresh = false}) {
    if (!forceRefresh && _pendingMonthFetch != null) {
      return _pendingMonthFetch!;
    }
    _pendingMonthFetch = _executeFetchMonthEvents();
    return _pendingMonthFetch!;
  }

  Future<void> _executeFetchMonthEvents() async {
    final requestId = ++_activeRequestId;
    _status = CalendarStatus.loading;
    notifyListeners();

    try {
      final list = await _apiService.getMonthEvents(
        year: _currentMonth.year,
        month: _currentMonth.month,
      );

      if (requestId != _activeRequestId) return;
      _events = list;
      _status = CalendarStatus.loaded;
      notifyListeners();
    } catch (e) {
      if (requestId != _activeRequestId) return;
      _status = CalendarStatus.error;
      _errorMessage = _resolveErrorMessage(e);
      notifyListeners();
    } finally {
      _pendingMonthFetch = null;
    }
  }

  /// Fetches categories.
  Future<void> fetchCategories() async {
    try {
      final list = await _apiService.getCategories();
      _categories = list;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to fetch categories: $e');
      }
    }
  }

  /// Fetches reminders and date-linked notes for the currently selected date.
  Future<void> fetchSelectedDateItems([DateTime? targetDate]) async {
    final date = targetDate ?? _selectedDate;
    final dateStr = formatDate(date);

    try {
      final remindersFuture = _apiService.getReminders(dateStr);
      final notesFuture = _apiService.getDateNotes(dateStr);

      final results = await Future.wait([remindersFuture, notesFuture]);

      _selectedDateReminders = results[0] as List<CalendarReminder>;
      _selectedDateNotes = results[1] as List<CalendarDateNote>;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[CalendarProvider] Error fetching items for date $dateStr: $e',
        );
      }
    }
  }

  // --- Event CRUD ---

  Future<CalendarEvent> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String categoryId,
    String? description,
    String? location,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final created = await _apiService.createEvent(
        title: title,
        startTime: startTime,
        endTime: endTime,
        categoryId: categoryId,
        description: description,
        location: location,
      );

      _events.add(created);
      _events.sort((a, b) => a.startTime.compareTo(b.startTime));

      sessionProvider?.logActivity(
        iconName: 'event',
        device: 'Current Device',
        module: 'Calendar',
        duration: '220ms',
        status: 'Success',
        description: 'Created event: "${created.title}"',
        category: 'Calendar',
      );

      // Trigger authoritative synchronization with backend
      fetchMonthEvents(forceRefresh: true).ignore();

      return created;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to create event: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Backwards-compatibility helper for creating events.
  Future<void> addEvent(CalendarEvent event) async {
    if (event.categoryId != null && event.categoryId!.isNotEmpty) {
      await createEvent(
        title: event.title,
        startTime: event.startTime,
        endTime: event.endTime,
        categoryId: event.categoryId!,
        description: event.description,
        location: event.location,
      );
    } else {
      // Find or create default category
      String catId = _categories.isNotEmpty ? _categories.first.id : '';
      if (catId.isEmpty) {
        final cat = await createCategory(name: 'General', color: '#3B82F6');
        catId = cat.id;
      }
      await createEvent(
        title: event.title,
        startTime: event.startTime,
        endTime: event.endTime,
        categoryId: catId,
        description: event.description,
        location: event.location,
      );
    }
  }

  Future<CalendarEvent> updateEvent(
    String id, {
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? categoryId,
    String? description,
    String? location,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final updated = await _apiService.updateEvent(
        id,
        title: title,
        startTime: startTime,
        endTime: endTime,
        categoryId: categoryId,
        description: description,
        location: location,
      );

      final idx = _events.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _events[idx] = updated;
        _events.sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      sessionProvider?.logActivity(
        iconName: 'event',
        device: 'Current Device',
        module: 'Calendar',
        duration: '180ms',
        status: 'Success',
        description: 'Updated event: "${updated.title}"',
        category: 'Calendar',
      );

      // Trigger authoritative synchronization with backend
      fetchMonthEvents(forceRefresh: true).ignore();

      return updated;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to update event $id: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    final target = _events.firstWhere(
      (e) => e.id == id,
      orElse: () => CalendarEvent(
        id: id,
        title: 'Event',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      ),
    );

    _pendingDeleteIds.add(id);
    notifyListeners();

    try {
      await _apiService.deleteEvent(id);
      _events.removeWhere((e) => e.id == id);

      sessionProvider?.logActivity(
        iconName: 'event_busy',
        device: 'Current Device',
        module: 'Calendar',
        duration: '190ms',
        status: 'Success',
        description: 'Deleted event: "${target.title}"',
        category: 'Calendar',
      );

      // Trigger authoritative synchronization with backend
      fetchMonthEvents(forceRefresh: true).ignore();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to delete event $id: $e');
      }
      rethrow;
    } finally {
      _pendingDeleteIds.remove(id);
      notifyListeners();
    }
  }

  // --- Category CRUD ---

  Future<CalendarCategory> createCategory({
    required String name,
    required String color,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final cat = await _apiService.createCategory(name: name, color: color);
      _categories.add(cat);
      return cat;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to create category: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // --- Reminder CRUD ---

  Future<CalendarReminder> createReminder({
    required String title,
    required String date,
    required String time,
    String? description,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final reminder = await _apiService.createReminder(
        title: title,
        date: date,
        time: time,
        description: description,
      );

      if (reminder.date == formatDate(_selectedDate)) {
        _selectedDateReminders.add(reminder);
      }

      sessionProvider?.logActivity(
        iconName: 'alarm',
        device: 'Current Device',
        module: 'Calendar',
        duration: '150ms',
        status: 'Success',
        description: 'Created reminder: "${reminder.title}"',
        category: 'Calendar',
      );

      return reminder;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to create reminder: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<CalendarReminder> updateReminder(
    String id, {
    String? title,
    String? date,
    String? time,
    String? description,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final reminder = await _apiService.updateReminder(
        id,
        title: title,
        date: date,
        time: time,
        description: description,
      );

      final idx = _selectedDateReminders.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _selectedDateReminders[idx] = reminder;
      }

      return reminder;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to update reminder $id: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> completeReminder(String id) async {
    _pendingCompleteIds.add(id);
    notifyListeners();

    try {
      final updated = await _apiService.completeReminder(id);
      final idx = _selectedDateReminders.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _selectedDateReminders[idx] = updated;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to complete reminder $id: $e');
      }
      rethrow;
    } finally {
      _pendingCompleteIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    _pendingDeleteIds.add(id);
    notifyListeners();

    try {
      await _apiService.deleteReminder(id);
      _selectedDateReminders.removeWhere((r) => r.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to delete reminder $id: $e');
      }
      rethrow;
    } finally {
      _pendingDeleteIds.remove(id);
      notifyListeners();
    }
  }

  // --- Date-Linked Note CRUD ---

  Future<CalendarDateNote> createDateNote({
    required String title,
    required String date,
    required String content,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final note = await _apiService.createDateNote(
        title: title,
        date: date,
        content: content,
      );

      if (note.date == formatDate(_selectedDate)) {
        _selectedDateNotes.add(note);
      }

      return note;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to create date note: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<CalendarDateNote> updateDateNote(
    String id, {
    String? title,
    String? content,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final note = await _apiService.updateDateNote(
        id,
        title: title,
        content: content,
      );

      final idx = _selectedDateNotes.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _selectedDateNotes[idx] = note;
      }

      return note;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to update date note $id: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteDateNote(String id) async {
    _pendingDeleteIds.add(id);
    notifyListeners();

    try {
      await _apiService.deleteDateNote(id);
      _selectedDateNotes.removeWhere((n) => n.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CalendarProvider] Failed to delete date note $id: $e');
      }
      rethrow;
    } finally {
      _pendingDeleteIds.remove(id);
      notifyListeners();
    }
  }

  // --- Global Search ---

  Future<void> searchCalendar(String query) async {
    final trimmed = query.trim();
    _searchQuery = trimmed;

    if (trimmed.isEmpty) {
      _searchResults = null;
      _isSearching = false;
      _searchError = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      final results = await _apiService.searchCalendar(trimmed);
      _searchResults = results;
    } catch (e) {
      _searchError = _resolveErrorMessage(e);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = null;
    _isSearching = false;
    _searchError = null;
    notifyListeners();
  }

  // --- Helpers ---

  String _resolveErrorMessage(Object error) {
    if (error is UnauthorizedException) {
      return 'Session expired. Please sign in again.';
    }
    if (error is NetworkException) {
      return 'Network connection issue. Please check your internet connection.';
    }
    if (error is ServerException) {
      return error.message;
    }
    return 'Unable to load calendar data right now. Please try again.';
  }
}
