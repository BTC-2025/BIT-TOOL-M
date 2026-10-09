import 'package:flutter/foundation.dart';
import '../api/api_exceptions.dart';
import '../models/note_model.dart';
import '../services/note_api_service.dart';
import 'auth_provider.dart';
import 'session_provider.dart';

/// Status of notes collection state.
enum NotesStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Centralized state management for notes, supporting full CRUD, cross-app notes,
/// search, filtering, pinning, archiving, and multi-account synchronization.
class NotesProvider extends ChangeNotifier {
  final NoteApiService _apiService;
  final SessionProvider? sessionProvider;

  NotesStatus _status = NotesStatus.initial;
  List<NoteModel> _notes = [];
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isSubmitting = false;
  String _selectedFilter = 'All Apps';
  String _searchQuery = '';

  /// IDs of notes currently undergoing mutation.
  final Set<String> _pendingDeleteIds = {};
  final Set<String> _pendingPinIds = {};
  final Set<String> _pendingArchiveIds = {};

  /// Monotonically increasing request counter to discard stale async responses.
  int _activeRequestId = 0;

  /// Tracks active user ID to ensure strict account isolation.
  String? _currentUserId;

  /// Reference to AuthProvider for session updates.
  AuthProvider? _authProvider;

  AuthProvider? get authProvider => _authProvider;

  NotesProvider([
    this.sessionProvider,
    NoteApiService? apiService,
    AuthProvider? authProvider,
    List<NoteModel>? initialNotes,
  ]) : _apiService = apiService ?? NoteApiService() {
    if (initialNotes != null && initialNotes.isNotEmpty) {
      _notes = List.from(initialNotes);
      _status = NotesStatus.loaded;
    }
    if (authProvider != null) {
      updateAuth(authProvider);
    }
  }

  // --- Getters ---

  NotesStatus get status => _status;
  List<NoteModel> get notes => List.unmodifiable(_notes);
  String? get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;
  bool get isSubmitting => _isSubmitting;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  bool get isLoading => _status == NotesStatus.loading;
  bool get hasError => _status == NotesStatus.error;
  bool get isLoaded => _status == NotesStatus.loaded;
  bool get isEmpty => isLoaded && _notes.isEmpty;

  bool isDeleting(String id) => _pendingDeleteIds.contains(id);
  bool isPinning(String id) => _pendingPinIds.contains(id);
  bool isArchiving(String id) => _pendingArchiveIds.contains(id);

  /// Filtered notes based on tab filter, archive state, and search query.
  List<NoteModel> get filteredNotes {
    final query = _searchQuery.trim().toLowerCase();

    return List.unmodifiable(
      _notes.where((n) {
        // Tab filtering
        if (_selectedFilter == 'Archived') {
          if (!n.isArchived) return false;
        } else {
          // Non-archived tabs should exclude archived notes
          if (n.isArchived) return false;

          if (_selectedFilter != 'All Apps' &&
              n.applicationName.toLowerCase() != _selectedFilter.toLowerCase()) {
            return false;
          }
        }

        // Search query filtering
        if (query.isNotEmpty) {
          final matchesTitle = n.title.toLowerCase().contains(query);
          final matchesContent = n.content.toLowerCase().contains(query);
          final matchesApp = n.applicationName.toLowerCase().contains(query);
          if (!matchesTitle && !matchesContent && !matchesApp) {
            return false;
          }
        }

        return true;
      }),
    );
  }

  // --- Multi-Account Synchronization ---

  /// Coordinates authentication changes and isolates note data between accounts.
  void updateAuth(AuthProvider authProvider) {
    _authProvider = authProvider;

    final newUserId = authProvider.user?.id.toString();

    if (!authProvider.isAuthenticated || newUserId == null) {
      if (_currentUserId != null || _notes.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[NotesProvider] User signed out or unauthenticated. Invalidating notes for account: $_currentUserId',
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
          '[NotesProvider] Account changed: previous=$_currentUserId -> new=$newUserId. Invalidating state and fetching notes for new account.',
        );
      }
      _invalidateState();
      _currentUserId = newUserId;
      fetchNotes(allApps: true, forceRefresh: true);
    }
  }

  void _invalidateState() {
    _activeRequestId++;
    _currentUserId = null;
    _notes = [];
    _status = NotesStatus.initial;
    _errorMessage = null;
    _isRefreshing = false;
    _isSubmitting = false;
    _pendingDeleteIds.clear();
    _pendingPinIds.clear();
    _pendingArchiveIds.clear();
    if (kDebugMode) {
      debugPrint('[NotesProvider] Notes state invalidated and cleared.');
    }
    notifyListeners();
  }

  // --- Read Operations ---

  /// Fetches notes from backend, using allApps=true for cross-application view.
  Future<void> fetchNotes({
    bool allApps = true,
    bool forceRefresh = false,
  }) async {
    if (_status == NotesStatus.loading && !forceRefresh) return;

    final requestId = ++_activeRequestId;
    final expectedUserId = _currentUserId;

    if (_notes.isEmpty || forceRefresh) {
      _status = NotesStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    if (kDebugMode) {
      debugPrint(
        '[NotesProvider] Fetching notes for account: $_currentUserId (requestId: $requestId, allApps: $allApps, forceRefresh: $forceRefresh)',
      );
    }

    try {
      final fetchedNotes = await _apiService.getNotes(allApps: allApps);

      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        if (kDebugMode) {
          debugPrint(
            '[NotesProvider] Discarding stale notes response (requestId: $requestId, active: $_activeRequestId).',
          );
        }
        return;
      }

      _notes = _sortNotes(fetchedNotes);
      _status = NotesStatus.loaded;
      _errorMessage = null;

      if (kDebugMode) {
        debugPrint(
          '[NotesProvider] Account: $_currentUserId | Loaded ${_notes.length} note(s).',
        );
      }
    } catch (e) {
      if (requestId != _activeRequestId || _currentUserId != expectedUserId) {
        return;
      }

      _status = NotesStatus.error;
      _errorMessage = _resolveErrorMessage(e);

      if (kDebugMode) {
        debugPrint('[NotesProvider] Error loading notes: $_errorMessage');
      }
    } finally {
      if (requestId == _activeRequestId) {
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Refreshes notes with pull-to-refresh animation.
  Future<void> refreshNotes({bool allApps = true}) async {
    _isRefreshing = true;
    notifyListeners();
    return fetchNotes(allApps: allApps, forceRefresh: true);
  }

  // --- CRUD Operations ---

  /// Creates a new note on the backend and updates local collection.
  Future<NoteModel> createNote({
    required String title,
    required String content,
    String? color,
    bool isPinned = false,
    String? applicationName,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final createdNote = await _apiService.createNote(
        title: title,
        content: content,
        color: color,
        isPinned: isPinned,
        applicationName: applicationName,
      );

      _notes.insert(0, createdNote);
      _notes = _sortNotes(_notes);

      sessionProvider?.logActivity(
        iconName: 'note_add',
        device: 'Current Device',
        module: 'Notes',
        duration: '180ms',
        status: 'Success',
        description: 'Created new note: "${createdNote.displayTitle}"',
        category: 'Notes',
      );

      if (kDebugMode) {
        debugPrint('[NotesProvider] Note created successfully: ${createdNote.id}');
      }

      return createdNote;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotesProvider] Create note failed: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Backwards-compatibility alias for [createNote].
  Future<void> addNote({
    required String title,
    required String content,
    String category = 'Bit Tool',
    String colorHex = '#A7F3D0',
    bool isPinned = false,
  }) async {
    await createNote(
      title: title,
      content: content,
      color: colorHex,
      isPinned: isPinned,
      applicationName: category,
    );
  }

  /// Updates an existing note on the backend.
  Future<NoteModel> updateNote(
    String id, {
    String? title,
    String? content,
    String? category,
    String? colorHex,
    bool? isPinned,
    bool? isArchived,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final updatedNote = await _apiService.updateNote(
        id,
        title: title,
        content: content,
        color: colorHex,
        isPinned: isPinned,
        isArchived: isArchived,
        applicationName: category,
      );

      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notes[index] = updatedNote;
      } else {
        _notes.insert(0, updatedNote);
      }
      _notes = _sortNotes(_notes);

      sessionProvider?.logActivity(
        iconName: 'edit_note',
        device: 'Current Device',
        module: 'Notes',
        duration: '120ms',
        status: 'Success',
        description: 'Updated note: "${updatedNote.displayTitle}"',
        category: 'Notes',
      );

      if (kDebugMode) {
        debugPrint('[NotesProvider] Note updated successfully: $id');
      }

      return updatedNote;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotesProvider] Update note failed for ID $id: $e');
      }
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Toggles note pinning status.
  Future<void> togglePin(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1 || _pendingPinIds.contains(id)) return;

    final currentPinned = _notes[index].isPinned;
    _pendingPinIds.add(id);
    notifyListeners();

    try {
      final updated = await _apiService.togglePin(id, !currentPinned);
      final idx = _notes.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notes[idx] = updated;
        _notes = _sortNotes(_notes);
      }

      sessionProvider?.logActivity(
        iconName: 'push_pin',
        device: 'Current Device',
        module: 'Notes',
        duration: '90ms',
        status: 'Success',
        description: '${!currentPinned ? "Pinned" : "Unpinned"} note: "${updated.displayTitle}"',
        category: 'Notes',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotesProvider] Toggle pin failed for $id: $e');
      }
      rethrow;
    } finally {
      _pendingPinIds.remove(id);
      notifyListeners();
    }
  }

  /// Toggles note archive status.
  Future<void> toggleArchive(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1 || _pendingArchiveIds.contains(id)) return;

    final currentArchived = _notes[index].isArchived;
    _pendingArchiveIds.add(id);
    notifyListeners();

    try {
      final updated = await _apiService.toggleArchive(id, !currentArchived);
      final idx = _notes.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _notes[idx] = updated;
        _notes = _sortNotes(_notes);
      }

      sessionProvider?.logActivity(
        iconName: 'inventory_2',
        device: 'Current Device',
        module: 'Notes',
        duration: '110ms',
        status: 'Success',
        description: '${!currentArchived ? "Archived" : "Restored"} note: "${updated.displayTitle}"',
        category: 'Notes',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotesProvider] Toggle archive failed for $id: $e');
      }
      rethrow;
    } finally {
      _pendingArchiveIds.remove(id);
      notifyListeners();
    }
  }

  /// Deletes a note permanently from backend and removes it from local state.
  Future<void> deleteNote(String id) async {
    if (_pendingDeleteIds.contains(id)) return;

    final targetNote = _notes.cast<NoteModel?>().firstWhere(
      (n) => n?.id == id,
      orElse: () => null,
    );

    _pendingDeleteIds.add(id);
    notifyListeners();

    try {
      await _apiService.deleteNote(id);
      _notes.removeWhere((n) => n.id == id);

      sessionProvider?.logActivity(
        iconName: 'delete',
        device: 'Current Device',
        module: 'Notes',
        duration: '150ms',
        status: 'Success',
        description: 'Deleted note: "${targetNote?.displayTitle ?? id}"',
        category: 'Notes',
      );

      if (kDebugMode) {
        debugPrint('[NotesProvider] Note deleted successfully: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotesProvider] Delete note failed for ID $id: $e');
      }
      rethrow;
    } finally {
      _pendingDeleteIds.remove(id);
      notifyListeners();
    }
  }

  // --- Filtering & Searching ---

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  /// Alias for [setFilter].
  void setSelectedFilter(String filter) => setFilter(filter);

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  // --- Helpers ---

  List<NoteModel> _sortNotes(List<NoteModel> list) {
    final sorted = List<NoteModel>.from(list);
    sorted.sort((a, b) {
      // 1. Pinned notes first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // 2. Updated / Created time descending
      final dateA = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return sorted;
  }

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
    return 'Unable to load notes right now. Please try again.';
  }
}
