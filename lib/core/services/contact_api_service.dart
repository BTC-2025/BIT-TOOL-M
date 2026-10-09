import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/api_exceptions.dart';
import '../auth/auth_storage.dart';
import '../models/contact_model.dart';

/// Dedicated service responsible for Contacts backend API communications.
class ContactApiService {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  ContactApiService({ApiClient? apiClient, AuthStorage? authStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _authStorage = authStorage ?? AuthStorage();

  /// Retrieves the persisted authentication token or throws [UnauthorizedException].
  Future<String> _requireToken() async {
    final token = await _authStorage.getToken();
    final hasToken = token != null && token.trim().isNotEmpty;
    if (kDebugMode) {
      debugPrint(
        '[ContactsAPI] Token availability: ${hasToken ? "Token present" : "No token found"}',
      );
    }
    if (!hasToken) {
      if (kDebugMode) {
        debugPrint(
          '[ContactsAPI] Aborting request: no authentication token available in storage.',
        );
      }
      throw const UnauthorizedException('No authentication token available.');
    }
    return token.trim();
  }

  /// Retrieves paginated contacts via GET /get.
  Future<PaginatedContactsResult> getPaginatedContacts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final token = await _requireToken();

    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final uri = ApiConfig.contactsGetUri(queryParams);
    if (kDebugMode) {
      debugPrint('[ContactsAPI] Final request: GET $uri');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      return _parsePaginatedResponse(raw, page: page, limit: limit);
    } catch (e) {
      _logError('getPaginatedContacts', e);
      rethrow;
    }
  }

  /// Retrieves all contacts via GET /get-all across all integrated applications.
  /// Handles backend default limits and retrieves complete collection for the authenticated
  /// account across applications, deduplicating records by unique contact ID.
  Future<List<ContactModel>> getAllContacts({int pageSize = 100}) async {
    final token = await _requireToken();
    final List<ContactModel> allContacts = [];
    final Set<String> seenIds = {};
    int offset = 0;
    int? totalCount;

    try {
      while (true) {
        final queryParams = <String, dynamic>{
          'offset': offset,
          'limit': pageSize,
        };

        final uri = ApiConfig.contactsGetAllUri(queryParams);
        if (kDebugMode) {
          debugPrint('[ContactsAPI] Final request: GET $uri');
          debugPrint(
            '[ContactsAPI] Query parameters: offset=$offset, limit=$pageSize',
          );
        }

        final dynamic raw = await _apiClient.get(uri, token: token);
        final List<ContactModel> batch = _extractContactsList(raw);

        // Extract total count if present in Sequelize response envelope
        if (raw is Map<String, dynamic>) {
          var countRaw = raw['count'] ?? raw['total'] ?? raw['totalRecords'] ?? raw['totalCount'];
          if (raw['data'] is Map<String, dynamic>) {
            final dataMap = raw['data'] as Map<String, dynamic>;
            countRaw ??= dataMap['count'] ?? dataMap['total'] ?? dataMap['totalRecords'] ?? dataMap['totalCount'];
          }
          if (countRaw is int) {
            totalCount = countRaw;
          } else if (countRaw != null) {
            totalCount = int.tryParse(countRaw.toString());
          }
        }

        for (final contact in batch) {
          if (contact.id.isEmpty || seenIds.add(contact.id)) {
            allContacts.add(contact);
          }
        }

        final bool hasMore = batch.length >= pageSize &&
            (totalCount == null || (offset + batch.length) < totalCount);

        if (kDebugMode) {
          debugPrint(
            '[ContactsAPI] GET $uri -> Status: 200 OK | Batch: ${batch.length} contact(s) | Cumulative: ${allContacts.length}/${totalCount ?? allContacts.length} | HasMore: $hasMore',
          );
        }

        if (!hasMore || batch.isEmpty) {
          break;
        }

        offset += batch.length;
      }

      if (kDebugMode) {
        debugPrint(
          '[ContactsAPI] getAllContacts completed: ${allContacts.length} total contact(s) retrieved (verified backend total: ${totalCount ?? allContacts.length}).',
        );
      }

      return allContacts;
    } catch (e) {
      _logError('getAllContacts', e);
      rethrow;
    }
  }

  /// Retrieves a single contact by ID via GET /get/:id.
  Future<ContactModel> getContactById(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const ApiException('Contact ID cannot be empty.');
    }

    final token = await _requireToken();
    final uri = ApiConfig.contactGetByIdUri(cleanId);
    if (kDebugMode) {
      debugPrint('[ContactsAPI] Final request: GET $uri');
    }

    try {
      final dynamic raw = await _apiClient.get(uri, token: token);
      if (raw is Map<String, dynamic>) {
        final data = raw['data'] ?? raw['contact'] ?? raw;
        if (data is Map<String, dynamic>) {
          return ContactModel.fromJson(data);
        }
      }
      throw const InvalidResponseException(
        'Server returned an invalid contact record format.',
      );
    } catch (e) {
      _logError('getContactById', e);
      rethrow;
    }
  }

  /// Creates a contact via POST /add with the documented schema:
  /// {
  ///   "firstName": "string",
  ///   "lastName": "string",
  ///   "email": "string",
  ///   "phone": "string",
  ///   "company": "string",
  ///   "notes": "string"
  /// Creates a contact via POST /add with the verified backend schema:
  /// {
  ///   "name": "string",
  ///   "email": "string",
  ///   "phonenumber": "string",
  ///   "role": "string" (optional)
  /// }
  Future<ContactModel> createContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? role,
  }) async {
    final token = await _requireToken();
    final uri = ApiConfig.contactAddUri;

    final fullName = ('$firstName $lastName').trim();
    final cleanEmail = (email ?? '').trim();
    final cleanPhone = (phone ?? '').trim();
    final cleanCompany = (company ?? '').trim();
    final cleanNotes = (notes ?? '').trim();
    final cleanRole = (role ?? '').trim();

    final body = <String, dynamic>{
      'name': fullName.isNotEmpty ? fullName : cleanEmail,
      'email': cleanEmail,
      'phonenumber': cleanPhone,
      if (cleanRole.isNotEmpty) 'role': cleanRole,
    };

    if (kDebugMode) {
      debugPrint('[ContactsAPI] Final request: POST $uri');
      debugPrint(
        '[ContactsAPI] Request payload keys: ${body.keys.toList()} | Name: ${body["name"]}',
      );
    }

    try {
      final dynamic raw = await _apiClient.post(uri, body: body, token: token);

      if (raw is Map<String, dynamic>) {
        final success = raw['success'];
        final status = raw['status']?.toString().toLowerCase();
        if (success == false || status == 'error') {
          final message =
              raw['message']?.toString() ?? 'Failed to create contact.';
          throw ApiException(message);
        }

        final data = raw['data'] ?? raw['contact'] ?? raw['result'];
        if (data is Map<String, dynamic>) {
          return ContactModel.fromJson(data);
        }

        // If backend responds with success envelope without full contact record
        final returnedId = raw['id']?.toString() ?? raw['contactId']?.toString();
        if (returnedId != null && returnedId.isNotEmpty) {
          return ContactModel(
            id: returnedId,
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            email: cleanEmail,
            phone: cleanPhone,
            company: cleanCompany,
            notes: cleanNotes,
            role: cleanRole,
          );
        }
      }

      // Fallback: construct model from form data if 2xx response has no id
      return ContactModel(
        id: '',
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        company: cleanCompany,
        notes: cleanNotes,
        role: cleanRole,
      );
    } catch (e) {
      _logError('createContact', e);
      rethrow;
    }
  }

  /// Updates an existing contact via PUT /update/:id with the verified schema.
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
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const ApiException('Contact ID cannot be empty.');
    }

    final token = await _requireToken();
    final uri = ApiConfig.contactUpdateUri(cleanId);

    final fullName = ('$firstName $lastName').trim();
    final cleanEmail = (email ?? '').trim();
    final cleanPhone = (phone ?? '').trim();
    final cleanCompany = (company ?? '').trim();
    final cleanNotes = (notes ?? '').trim();
    final cleanRole = (role ?? '').trim();

    final body = <String, dynamic>{
      'name': fullName.isNotEmpty ? fullName : cleanEmail,
      'email': cleanEmail,
      'phonenumber': cleanPhone,
      if (cleanRole.isNotEmpty) 'role': cleanRole,
    };

    if (kDebugMode) {
      debugPrint('[ContactsAPI] Final request: PUT $uri');
      debugPrint(
        '[ContactsAPI] Request payload keys: ${body.keys.toList()} | Name: ${body["name"]}',
      );
    }

    try {
      final dynamic raw = await _apiClient.put(uri, body: body, token: token);

      if (raw is Map<String, dynamic>) {
        final success = raw['success'];
        final status = raw['status']?.toString().toLowerCase();
        if (success == false || status == 'error') {
          final message =
              raw['message']?.toString() ?? 'Failed to update contact.';
          throw ApiException(message);
        }

        final data = raw['data'] ?? raw['contact'] ?? raw['result'];
        if (data is Map<String, dynamic>) {
          return ContactModel.fromJson(data);
        }
      }

      return ContactModel(
        id: cleanId,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        company: cleanCompany,
        notes: cleanNotes,
        role: cleanRole,
      );
    } catch (e) {
      _logError('updateContact', e);
      rethrow;
    }
  }

  /// Deletes a contact via DELETE /delete/:id.
  Future<bool> deleteContact(String id) async {
    final cleanId = id.trim();
    if (cleanId.isEmpty) {
      throw const ApiException('Contact ID cannot be empty.');
    }

    final token = await _requireToken();
    final uri = ApiConfig.contactDeleteUri(cleanId);
    if (kDebugMode) {
      debugPrint('[ContactsAPI] Final request: DELETE $uri');
    }

    try {
      final dynamic raw = await _apiClient.delete(uri, token: token);

      if (raw is Map<String, dynamic>) {
        final success = raw['success'];
        final status = raw['status']?.toString().toLowerCase();
        if (success == false || status == 'error') {
          final message =
              raw['message']?.toString() ?? 'Failed to delete contact.';
          throw ApiException(message);
        }
      }

      if (kDebugMode) {
        debugPrint('[ContactsAPI] DELETE successful for contact ID: $cleanId');
      }
      return true;
    } catch (e) {
      _logError('deleteContact', e);
      rethrow;
    }
  }

  /// Parses list of contacts from any supported envelope format.
  List<ContactModel> _extractContactsList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((item) => ContactModel.fromJson(item))
          .toList();
    }

    if (raw is Map<String, dynamic>) {
      final success = raw['success'];
      final status = raw['status']?.toString().toLowerCase();
      if (success == false || status == 'error') {
        final message =
            raw['message']?.toString() ?? 'Failed to retrieve contacts.';
        throw ApiException(message);
      }

      var listData =
          raw['data'] ??
          raw['contacts'] ??
          raw['rows'] ??
          raw['results'] ??
          raw['items'] ??
          raw['records'];

      if (listData is Map<String, dynamic>) {
        listData =
            listData['rows'] ??
            listData['contacts'] ??
            listData['items'] ??
            listData['results'] ??
            listData['records'] ??
            listData['data'];
      }

      if (listData is List) {
        return listData
            .whereType<Map<String, dynamic>>()
            .map((item) => ContactModel.fromJson(item))
            .toList();
      }

      if (raw.containsKey('data') && raw['data'] == null) {
        return [];
      }
    }

    throw const InvalidResponseException(
      'Server returned an unexpected contacts list response format.',
    );
  }

  /// Parses paginated response into [PaginatedContactsResult].
  PaginatedContactsResult _parsePaginatedResponse(
    dynamic raw, {
    required int page,
    required int limit,
  }) {
    if (raw is List) {
      final contacts = raw
          .whereType<Map<String, dynamic>>()
          .map((item) => ContactModel.fromJson(item))
          .toList();
      return PaginatedContactsResult(
        contacts: contacts,
        pagination: ContactPagination(
          page: page,
          limit: limit,
          total: contacts.length,
          totalPages: (contacts.length / limit).ceil().clamp(1, 99999),
        ),
      );
    }

    if (raw is Map<String, dynamic>) {
      final contacts = _extractContactsList(raw);

      // Check for pagination metadata
      ContactPagination pagination;
      final paginationRaw =
          raw['pagination'] ??
          raw['meta'] ??
          raw['metadata'] ??
          (raw['data'] is Map<String, dynamic>
              ? (raw['data'] as Map<String, dynamic>)['pagination']
              : null);

      if (paginationRaw is Map<String, dynamic>) {
        pagination = ContactPagination.fromJson(paginationRaw);
      } else {
        final dataMap = raw['data'] is Map<String, dynamic>
            ? raw['data'] as Map<String, dynamic>
            : null;
        final totalRaw =
            dataMap?['count'] ??
            dataMap?['total'] ??
            raw['total'] ??
            raw['totalRecords'] ??
            raw['totalCount'] ??
            raw['count'] ??
            contacts.length;

        final total = totalRaw is int
            ? totalRaw
            : (int.tryParse(totalRaw.toString()) ?? contacts.length);

        final totalPages = limit > 0
            ? (total / limit).ceil().clamp(1, 99999)
            : 1;

        pagination = ContactPagination(
          page: page,
          limit: limit,
          total: total,
          totalPages: totalPages,
        );
      }

      return PaginatedContactsResult(
        contacts: contacts,
        pagination: pagination,
      );
    }

    throw const InvalidResponseException(
      'Server returned an unexpected contacts response format.',
    );
  }

  void _logError(String operation, Object e) {
    if (kDebugMode) {
      debugPrint('[ContactsAPI] Error in $operation: $e');
      if (e is ServerException) {
        debugPrint('[ContactsAPI] Server error status code: ${e.statusCode}');
        if (e.correlationId != null) {
          debugPrint('[ContactsAPI] Correlation ID: ${e.correlationId}');
        }
        if (e.responseBody != null && e.responseBody!.isNotEmpty) {
          debugPrint('[ContactsAPI] Response body: ${e.responseBody}');
        }
      }
    }
  }
}
