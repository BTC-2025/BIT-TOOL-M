import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/models/contact_model.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/contacts_provider.dart';
import 'package:bit_tools_backend/core/services/contact_api_service.dart';

class FakeContactApiService implements ContactApiService {
  List<ContactModel> mockContacts = [];
  ContactPagination mockPagination = const ContactPagination(
    page: 1,
    limit: 20,
    total: 0,
    totalPages: 1,
  );
  Exception? errorToThrow;
  int getPaginatedCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<PaginatedContactsResult> getPaginatedContacts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    getPaginatedCalls++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return PaginatedContactsResult(
      contacts: mockContacts,
      pagination: mockPagination,
    );
  }

  @override
  Future<List<ContactModel>> getAllContacts({int pageSize = 100}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockContacts;
  }

  @override
  Future<ContactModel> getContactById(String id) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mockContacts.firstWhere((c) => c.id == id);
  }

  @override
  Future<ContactModel> createContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? role,
  }) async {
    createCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final created = ContactModel(
      id: 'new-id',
      firstName: firstName,
      lastName: lastName,
      email: email ?? '',
      phone: phone ?? '',
      company: company ?? '',
      notes: notes ?? '',
      role: role ?? '',
    );
    mockContacts.add(created);
    return created;
  }

  @override
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
    updateCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    final updated = ContactModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email ?? '',
      phone: phone ?? '',
      company: company ?? '',
      notes: notes ?? '',
      role: role ?? '',
    );
    final idx = mockContacts.indexWhere((c) => c.id == id);
    if (idx != -1) mockContacts[idx] = updated;
    return updated;
  }

  @override
  Future<bool> deleteContact(String id) async {
    deleteCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    mockContacts.removeWhere((c) => c.id == id);
    return true;
  }
}

class FakeAuthProvider extends AuthProvider {
  bool _mockAuth = true;
  UserModel? _mockUser = const UserModel(
    id: 1,
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    role: 'ADMIN',
  );

  @override
  bool get isAuthenticated => _mockAuth;

  @override
  UserModel? get user => _mockUser;

  void setAuthenticated(bool authenticated, [UserModel? user]) {
    _mockAuth = authenticated;
    _mockUser = user;
    notifyListeners();
  }
}

void main() {
  group('ContactsProvider Tests', () {
    late FakeContactApiService fakeService;
    late FakeAuthProvider fakeAuth;
    late ContactsProvider provider;

    setUp(() {
      fakeService = FakeContactApiService();
      fakeAuth = FakeAuthProvider();
      provider = ContactsProvider(null, fakeService, fakeAuth);
    });

    test('initial state contains no hardcoded or fake contacts', () {
      final unauthProvider = ContactsProvider(null, fakeService);
      expect(unauthProvider.status, ContactsStatus.initial);
      expect(unauthProvider.contacts, isEmpty);
      expect(unauthProvider.filteredContacts, isEmpty);
      expect(unauthProvider.hasError, isFalse);
      expect(unauthProvider.errorMessage, isNull);

      // Authenticated provider initialized in setUp automatically fetched contacts
      expect(provider.contacts, isEmpty);
      expect(provider.hasError, isFalse);
    });

    test('fetchContacts loads real records and sets status to loaded', () async {
      fakeService.mockContacts = [
        const ContactModel(
          id: '1',
          firstName: 'Hal',
          lastName: 'Jordan',
          email: 'hal@sector2814.org',
          company: 'Green Lantern Corps',
        ),
      ];
      fakeService.mockPagination = const ContactPagination(
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      );

      await provider.fetchContacts();

      expect(provider.status, ContactsStatus.loaded);
      expect(provider.contacts.length, 1);
      expect(provider.contacts.first.fullName, 'Hal Jordan');
      expect(provider.isEmpty, isFalse);
    });

    test('fetchContacts with 0 records sets empty state cleanly', () async {
      fakeService.mockContacts = [];

      await provider.fetchContacts();

      expect(provider.status, ContactsStatus.loaded);
      expect(provider.contacts, isEmpty);
      expect(provider.isEmpty, isTrue);
    });

    test('fetchContacts failure sets error status and message', () async {
      fakeService.errorToThrow = const ServerException(
        'Server encountered an issue',
        500,
      );

      await provider.fetchContacts();

      expect(provider.status, ContactsStatus.error);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, 'Server encountered an issue');
      expect(provider.contacts, isEmpty);
    });

    test('createContact calls service and refreshes contacts list', () async {
      fakeService.mockContacts = [];

      await provider.createContact(
        firstName: 'John',
        lastName: 'Stewart',
        email: 'john@glc.org',
      );

      expect(fakeService.createCalls, 1);
      expect(provider.contacts.length, 1);
      expect(provider.contacts.first.fullName, 'John Stewart');
    });

    test('updateContact updates contact and refreshes state', () async {
      fakeService.mockContacts = [
        const ContactModel(
          id: 'c1',
          firstName: 'Oliver',
          lastName: 'Queen',
          company: 'Queen Industries',
        ),
      ];

      await provider.fetchContacts();

      await provider.updateContact(
        'c1',
        firstName: 'Oliver',
        lastName: 'Queen',
        company: 'Star City Mayor Office',
      );

      expect(fakeService.updateCalls, 1);
      expect(provider.contacts.first.company, 'Star City Mayor Office');
    });

    test('deleteContact removes contact from local collection', () async {
      fakeService.mockContacts = [
        const ContactModel(
          id: 'c1',
          firstName: 'Dinah',
          lastName: 'Lance',
        ),
      ];
      fakeService.mockPagination = const ContactPagination(
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      );

      await provider.fetchContacts();
      expect(provider.contacts.length, 1);

      final success = await provider.deleteContact('c1');

      expect(success, isTrue);
      expect(fakeService.deleteCalls, 1);
      expect(provider.contacts, isEmpty);
      expect(provider.totalRecords, 0);
    });

    test('searchQuery filters contacts in memory accurately', () async {
      fakeService.mockContacts = [
        const ContactModel(
          id: '1',
          firstName: 'Bruce',
          lastName: 'Wayne',
          company: 'Wayne Enterprises',
          email: 'bruce@wayne.com',
        ),
        const ContactModel(
          id: '2',
          firstName: 'Dick',
          lastName: 'Grayson',
          company: 'Bludhaven PD',
          email: 'dick@bpd.gov',
        ),
      ];

      await provider.fetchContacts();

      // Search by last name
      provider.setSearchQuery('wayne');
      expect(provider.filteredContacts.length, 1);
      expect(provider.filteredContacts.first.fullName, 'Bruce Wayne');

      // Search by company
      provider.setSearchQuery('bludhaven');
      expect(provider.filteredContacts.length, 1);
      expect(provider.filteredContacts.first.fullName, 'Dick Grayson');

      // Clear search
      provider.setSearchQuery('');
      expect(provider.filteredContacts.length, 2);
    });

    test('multi-account isolation: account change clears contacts and refetches', () async {
      fakeService.mockContacts = [
        const ContactModel(id: '1', firstName: 'User1', lastName: 'Contact'),
      ];

      await provider.fetchContacts();
      expect(provider.contacts.length, 1);

      // Switch to another account
      fakeService.mockContacts = [
        const ContactModel(id: '2', firstName: 'User2', lastName: 'Contact'),
      ];
      fakeAuth.setAuthenticated(
        true,
        const UserModel(
          id: 2,
          email: 'user2@example.com',
          firstName: 'Second',
          lastName: 'User',
          role: 'USER',
        ),
      );
      provider.updateAuth(fakeAuth);

      // In-flight refresh will populate user2's contacts
      await pumpEventQueue();

      expect(provider.contacts.length, 1);
      expect(provider.contacts.first.fullName, 'User2 Contact');
    });

    test('signing out clears in-memory contacts immediately', () async {
      fakeService.mockContacts = [
        const ContactModel(id: '1', firstName: 'Sensitive', lastName: 'Contact'),
      ];

      await provider.fetchContacts();
      expect(provider.contacts.isNotEmpty, isTrue);

      fakeAuth.setAuthenticated(false, null);
      provider.updateAuth(fakeAuth);

      expect(provider.contacts, isEmpty);
      expect(provider.status, ContactsStatus.initial);
    });

    test('multi-account switching between account 149 and account 269 preserves strict isolation', () async {
      // 1. Account 149 has 2 contacts
      fakeAuth.setAuthenticated(
        true,
        const UserModel(
          id: 149,
          email: 'ravinew2004@bnxmail.com',
          firstName: 'Ravi',
          lastName: 'Kumar',
          role: 'USER',
        ),
      );
      fakeService.mockContacts = [
        const ContactModel(id: 'c1', firstName: 'Ashwin', lastName: 'Kumar', email: 'ashwin@bnxmail.com'),
        const ContactModel(id: 'c2', firstName: 'Virat', lastName: 'Kholi', email: 'virat@bnxmail.com'),
      ];
      provider.updateAuth(fakeAuth);
      await pumpEventQueue();

      expect(provider.contacts.length, 2);
      expect(provider.contacts.map((c) => c.fullName).toList(), ['Ashwin Kumar', 'Virat Kholi']);

      // 2. Switch to Account 269 (has 0 contacts in backend)
      fakeAuth.setAuthenticated(
        true,
        const UserModel(
          id: 269,
          email: 'emptyaccount@bnxmail.com',
          firstName: 'Empty',
          lastName: 'Account',
          role: 'USER',
        ),
      );
      fakeService.mockContacts = [];
      provider.updateAuth(fakeAuth);
      await pumpEventQueue();

      expect(provider.contacts, isEmpty);
      expect(provider.isEmpty, isTrue);
      expect(provider.status, ContactsStatus.loaded);

      // 3. Switch back to Account 149
      fakeAuth.setAuthenticated(
        true,
        const UserModel(
          id: 149,
          email: 'ravinew2004@bnxmail.com',
          firstName: 'Ravi',
          lastName: 'Kumar',
          role: 'USER',
        ),
      );
      fakeService.mockContacts = [
        const ContactModel(id: 'c1', firstName: 'Ashwin', lastName: 'Kumar', email: 'ashwin@bnxmail.com'),
        const ContactModel(id: 'c2', firstName: 'Virat', lastName: 'Kholi', email: 'virat@bnxmail.com'),
      ];
      provider.updateAuth(fakeAuth);
      await pumpEventQueue();

      expect(provider.contacts.length, 2);
      expect(provider.contacts.map((c) => c.fullName).toList(), ['Ashwin Kumar', 'Virat Kholi']);
    });
  });
}
