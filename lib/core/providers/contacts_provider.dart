import 'package:flutter/foundation.dart';
import '../api/api_exceptions.dart';
import '../models/contact_model.dart';
import '../services/contact_api_service.dart';
import 'auth_provider.dart';
import 'session_provider.dart';

/// Status of contacts collection state.
enum ContactsStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Centralized state management for contacts, supporting full CRUD, search, pagination,
/// and multi-account synchronization.
class ContactsProvider extends ChangeNotifier {
  final ContactApiService _apiService;
  final SessionProvider? sessionProvider;

  ContactsStatus _status = ContactsStatus.initial;
  List<ContactModel> _contacts = [];
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isSubmitting = false;
  String _searchQuery = '';
  ContactPagination _pagination = const ContactPagination();

  /// IDs of contacts currently being deleted via backend API.
  final Set<String> _pendingDeleteIds = {};

  /// Monotonically increasing request counter to discard stale async responses.
  int _activeRequestId = 0;

  /// Tracks active user ID to ensure account isolation and prevent cross-account leakage.
  String? _currentUserId;

  /// Reference to AuthProvider for session updates and token-expiration coordination.
  AuthProvider? _authProvider;

  ContactsProvider([
    this.sessionProvider,
    ContactApiService? apiService,
    AuthProvider? authProvider,
    List<ContactModel>? initialContacts,
  ]) : _apiService = apiService ?? ContactApiService() {
    if (initialContacts != null && initialContacts.isNotEmpty) {
      _contacts = List.from(initialContacts);
      _status = ContactsStatus.loaded;
    }
    if (authProvider != null) {
      updateAuth(authProvider);
    }
  }

  // --- Getters ---

  ContactsStatus get status => _status;
  List<ContactModel> get contacts => List.unmodifiable(_contacts);
  String? get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;
  bool get isSubmitting => _isSubmitting;
  String get searchQuery => _searchQuery;
  ContactPagination get pagination => _pagination;

  bool get isLoading => _status == ContactsStatus.loading;
  bool get hasError => _status == ContactsStatus.error;
  bool get isLoaded => _status == ContactsStatus.loaded;
  bool get isEmpty => isLoaded && _contacts.isEmpty;

  int get currentPage => _pagination.page;
  int get totalPages => _pagination.totalPages;
  int get totalRecords => _pagination.total;
  bool get hasNextPage => _pagination.hasNextPage;
  bool get hasPreviousPage => _pagination.hasPreviousPage;

  bool isDeleting(String id) => _pendingDeleteIds.contains(id);

  /// Filtered contacts based on the current in-memory search query.
  List<ContactModel> get filteredContacts {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return List.unmodifiable(_contacts);
    }
    return List.unmodifiable(
      _contacts.where((c) {
        return c.firstName.toLowerCase().contains(query) ||
            c.lastName.toLowerCase().contains(query) ||
            c.fullName.toLowerCase().contains(query) ||
            c.email.toLowerCase().contains(query) ||
            c.phone.toLowerCase().contains(query) ||
            c.company.toLowerCase().contains(query) ||
            c.role.toLowerCase().contains(query) ||
            c.department.toLowerCase().contains(query);
      }),
    );
  }

  // --- Multi-Account Synchronization ---

  /// Synchronizes contacts with the active [AuthProvider].
  ///
  /// Clears in-memory contacts immediately if the active user changes or signs out.
  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    final newUserId = auth.user?.id.toString();

    if (!auth.isAuthenticated || newUserId == null) {
      if (_currentUserId != null || _contacts.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[ContactsProvider] User signed out or unauthenticated. Invalidating contacts for account: $_currentUserId',
          );
        }
        clear();
      }
      _currentUserId = null;
      return;
    }

    if (newUserId != _currentUserId) {
      if (kDebugMode) {
        debugPrint(
          '[ContactsProvider] Account changed: previous=$_currentUserId -> new=$newUserId. Invalidating state and fetching contacts for new account.',
        );
      }
      clear();
      _currentUserId = newUserId;
      fetchContacts();
    }
  }

  // --- Search ---

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  // --- Fetch Contacts ---

  Future<void>? _pendingFetch;

  /// Retrieves contacts via GET /get (paginated endpoint).
  Future<void> fetchContacts({
    int page = 1,
    bool forceRefresh = false,
  }) {
    if (_pendingFetch != null && !forceRefresh) {
      return _pendingFetch!;
    }
    _pendingFetch = _executeFetch(page: page, forceRefresh: forceRefresh);
    return _pendingFetch!;
  }

  Future<void> _executeFetch({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final auth = _authProvider;
    if (auth != null && !auth.isAuthenticated) {
      if (kDebugMode) {
        debugPrint(
          '[ContactsProvider] AuthProvider is unauthenticated. Cannot fetch contacts without active session.',
        );
      }
      _status = ContactsStatus.error;
      _errorMessage = 'Please sign in to view contacts.';
      _contacts = [];
      notifyListeners();
      return;
    }

    final int requestId = ++_activeRequestId;
    final String? expectedUserId = _currentUserId;

    if (kDebugMode) {
      debugPrint(
        '[ContactsProvider] Fetching contacts for account ID: $_currentUserId (requestId: $requestId, page: $page, forceRefresh: $forceRefresh)',
      );
    }

    if (forceRefresh && _contacts.isNotEmpty) {
      _isRefreshing = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _status = ContactsStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final items = await _apiService.getAllContacts();

      // Discard stale response if another request was triggered or account changed
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        if (kDebugMode) {
          debugPrint(
            '[ContactsProvider] Stale response discarded (active: $_activeRequestId vs request: $requestId, user: $_currentUserId vs expected: $expectedUserId).',
          );
        }
        return;
      }

      _contacts = items;
      _pagination = ContactPagination(
        page: 1,
        limit: items.isNotEmpty ? items.length : 20,
        total: items.length,
        totalPages: 1,
      );
      _status = ContactsStatus.loaded;
      _errorMessage = null;

      if (kDebugMode) {
        debugPrint(
          '[ContactsProvider] Account ID: $_currentUserId | Loaded ${_contacts.length} contacts across applications (verified total: ${_pagination.total}).',
        );
      }
    } on UnauthorizedException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) return;
      _status = ContactsStatus.error;
      _errorMessage = e.message;
      _contacts = [];
      await _authProvider?.signOut();
    } on ForbiddenException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) return;
      _status = ContactsStatus.error;
      _errorMessage = e.message;
    } on NetworkException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) return;
      _status = ContactsStatus.error;
      _errorMessage = e.message;
    } on RequestTimeoutException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) return;
      _status = ContactsStatus.error;
      _errorMessage = e.message;
    } on ServerException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) return;
      _status = ContactsStatus.error;
      _errorMessage = e.message;
    } on ApiException catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) return;
      _status = ContactsStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) return;
      _status = ContactsStatus.error;
      _errorMessage = 'Failed to load contacts. Please try again.';
      if (kDebugMode) {
        debugPrint('[ContactsProvider] Unexpected error in fetchContacts: $e');
      }
    } finally {
      _pendingFetch = null;
      if (requestId == _activeRequestId && _currentUserId == expectedUserId) {
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Retrieves all contacts via GET /get-all across all integrated applications.
  Future<void> fetchAllContacts({bool forceRefresh = false}) =>
      fetchContacts(forceRefresh: forceRefresh);

  /// Force-refreshes contacts for the active account.
  Future<void> refreshContacts() => fetchContacts(forceRefresh: true);

  // --- CRUD Operations ---

  /// Creates a new contact via POST /add, refreshes list from backend on confirmed success.
  Future<ContactModel> createContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? role,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final created = await _apiService.createContact(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        company: company,
        notes: notes,
        role: role,
      );

      sessionProvider?.logActivity(
        iconName: 'person_add',
        device: 'Current Device',
        module: 'Contacts',
        duration: '150ms',
        status: 'Success',
        description: 'Created contact: "${created.fullName}"',
        category: 'Contacts',
      );

      // Refresh list from the backend to ensure authoritative data
      await fetchContacts(page: _pagination.page, forceRefresh: true);

      return created;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Updates an existing contact via PUT /update/:id, refreshes list on confirmed success.
  Future<ContactModel> updateContact(
    String id, {
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? role,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final updated = await _apiService.updateContact(
        id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        company: company,
        notes: notes,
        role: role,
      );

      sessionProvider?.logActivity(
        iconName: 'edit',
        device: 'Current Device',
        module: 'Contacts',
        duration: '150ms',
        status: 'Success',
        description: 'Updated contact: "${updated.fullName}"',
        category: 'Contacts',
      );

      // Refresh list from backend to maintain consistency
      await fetchContacts(page: _pagination.page, forceRefresh: true);

      return updated;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Deletes a contact via DELETE /delete/:id on the backend.
  Future<bool> deleteContact(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty || _pendingDeleteIds.contains(cleanId)) {
      return false;
    }

    _pendingDeleteIds.add(cleanId);
    notifyListeners();

    try {
      final success = await _apiService.deleteContact(cleanId);
      if (success) {
        final existingIndex = _contacts.indexWhere((c) => c.id == cleanId);
        final deletedName = existingIndex != -1
            ? _contacts[existingIndex].fullName
            : cleanId;

        _contacts.removeWhere((c) => c.id == cleanId);

        sessionProvider?.logActivity(
          iconName: 'person_remove',
          device: 'Current Device',
          module: 'Contacts',
          duration: '120ms',
          status: 'Success',
          description: 'Deleted contact: "$deletedName"',
          category: 'Contacts',
        );

        // Update pagination total count
        if (_pagination.total > 0) {
          final newTotal = _pagination.total - 1;
          final newPages = (_pagination.limit > 0 && newTotal > 0)
              ? (newTotal / _pagination.limit).ceil()
              : 1;
          _pagination = ContactPagination(
            page: _pagination.page > newPages ? newPages : _pagination.page,
            limit: _pagination.limit,
            total: newTotal,
            totalPages: newPages,
          );
        }

        notifyListeners();
        return true;
      }
      return false;
    } finally {
      _pendingDeleteIds.remove(cleanId);
      notifyListeners();
    }
  }

  /// Resets in-memory state.
  void clear() {
    _status = ContactsStatus.initial;
    _contacts = [];
    _errorMessage = null;
    _isRefreshing = false;
    _isSubmitting = false;
    _searchQuery = '';
    _pagination = const ContactPagination();
    _pendingDeleteIds.clear();
    _pendingFetch = null;
    if (kDebugMode) {
      debugPrint('[ContactsProvider] Contacts state invalidated and cleared.');
    }
    notifyListeners();
  }
}
