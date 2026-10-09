import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/models/contact_model.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/contacts_provider.dart';
import 'package:bit_tools_backend/core/services/contact_api_service.dart';
import 'package:bit_tools_backend/features/contacts/contacts_screen.dart';

class MockTestContactApiService implements ContactApiService {
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
    final created = ContactModel(
      id: 'created-id-1',
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
    return ContactModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      role: role ?? '',
    );
  }

  @override
  Future<bool> deleteContact(String id) async {
    deleteCalls++;
    mockContacts.removeWhere((c) => c.id == id);
    return true;
  }
}

class MockTestAuthProvider extends AuthProvider {
  @override
  bool get isAuthenticated => true;

  @override
  UserModel? get user => const UserModel(
    id: 1,
    email: 'admin@bit-tool.com',
    firstName: 'Admin',
    lastName: 'User',
    role: 'ADMIN',
  );
}

Widget _wrapWithProviders({
  required ContactsProvider contactsProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ContactsProvider>.value(value: contactsProvider),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: ContactsScreen(),
      ),
    ),
  );
}

void main() {
  group('ContactsScreen Widget Tests', () {
    late MockTestContactApiService mockService;
    late MockTestAuthProvider mockAuth;

    setUp(() {
      mockService = MockTestContactApiService();
      mockAuth = MockTestAuthProvider();
    });

    testWidgets('renders Contact Management header and search bar', (
      WidgetTester tester,
    ) async {
      final provider = ContactsProvider(null, mockService, mockAuth);

      await tester.pumpWidget(_wrapWithProviders(contactsProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Contact Management'), findsOneWidget);
      expect(
        find.text('Manage your contacts across all integrated applications.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('New Contact'), findsOneWidget);
    });

    testWidgets('displays error state and Retry button on failure', (
      WidgetTester tester,
    ) async {
      mockService.errorToThrow = const ServerException('Server error', 500);
      final provider = ContactsProvider(null, mockService, mockAuth);

      await tester.pumpWidget(_wrapWithProviders(contactsProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Server error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now fix backend and tap Retry
      mockService.errorToThrow = null;
      mockService.mockContacts = [
        const ContactModel(
          id: '1',
          firstName: 'Bruce',
          lastName: 'Wayne',
        ),
      ];

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Bruce Wayne'), findsOneWidget);
    });

    testWidgets('displays empty state when zero contacts returned', (
      WidgetTester tester,
    ) async {
      mockService.mockContacts = [];
      final provider = ContactsProvider(null, mockService, mockAuth);

      await tester.pumpWidget(_wrapWithProviders(contactsProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('No contacts found.'), findsOneWidget);
    });

    testWidgets('displays real contact row without fake fallback email/phone', (
      WidgetTester tester,
    ) async {
      mockService.mockContacts = [
        const ContactModel(
          id: '1',
          firstName: 'Tony',
          lastName: 'Stark',
          email: 'tony@starkindustries.com',
          phone: '+1 800 STARK',
          company: 'Stark Industries',
          role: 'CEO',
        ),
      ];
      mockService.mockPagination = const ContactPagination(
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      );
      final provider = ContactsProvider(null, mockService, mockAuth);

      await tester.pumpWidget(_wrapWithProviders(contactsProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Tony Stark'), findsOneWidget);
      expect(find.text('tony@starkindustries.com'), findsOneWidget);
      expect(find.text('+1 800 STARK'), findsOneWidget);
      expect(find.text('CEO'), findsOneWidget);

      // Verify hardcoded fake fallback data is NEVER present
      expect(find.text('aruntest@bnxmail.com'), findsNothing);
      expect(find.text('8984724747'), findsNothing);
      expect(find.text('virat kholi'), findsNothing);
      expect(find.text('Chithappa'), findsNothing);
    });

    testWidgets('search filters contact rows interactively', (
      WidgetTester tester,
    ) async {
      mockService.mockContacts = [
        const ContactModel(
          id: '1',
          firstName: 'Peter',
          lastName: 'Parker',
          email: 'peter@dailybugle.com',
        ),
        const ContactModel(
          id: '2',
          firstName: 'Stephen',
          lastName: 'Strange',
          email: 'strange@sanctum.org',
        ),
      ];
      final provider = ContactsProvider(null, mockService, mockAuth);

      await tester.pumpWidget(_wrapWithProviders(contactsProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Peter Parker'), findsOneWidget);
      expect(find.text('Stephen Strange'), findsOneWidget);

      // Enter search term
      await tester.enterText(find.byType(TextField).first, 'strange');
      await tester.pumpAndSettle();

      expect(find.text('Peter Parker'), findsNothing);
      expect(find.text('Stephen Strange'), findsOneWidget);
    });

    testWidgets('opens Create New Contact dialog and creates contact', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockService.mockContacts = [];
      final provider = ContactsProvider(null, mockService, mockAuth);

      await tester.pumpWidget(_wrapWithProviders(contactsProvider: provider));
      await tester.pumpAndSettle();

      // Tap New Contact button
      await tester.tap(find.text('New Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Create New Contact'), findsOneWidget);

      // Fill Name and Email
      final textFields = find.byType(TextField);
      // textFields: [0]=search, [1]=Full Name, [2]=Email, [3]=Phone, [4]=Company, [5]=Notes
      await tester.enterText(textFields.at(1), 'Steve Rogers');
      await tester.enterText(textFields.at(2), 'steve@avengers.org');

      // Submit Create Contact
      final submitBtn = find.widgetWithText(ElevatedButton, 'Create Contact');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockService.createCalls, 1);
      expect(find.text('Contact created successfully.'), findsOneWidget);
      expect(find.text('Steve Rogers'), findsOneWidget);
    });

    testWidgets('clicking delete icon opens confirmation dialog and deletes contact', (
      WidgetTester tester,
    ) async {
      mockService.mockContacts = [
        const ContactModel(
          id: 'del-1',
          firstName: 'Natasha',
          lastName: 'Romanoff',
        ),
      ];
      final provider = ContactsProvider(null, mockService, mockAuth);

      await tester.pumpWidget(_wrapWithProviders(contactsProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Natasha Romanoff'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete Contact'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to delete "Natasha Romanoff"?'),
        findsOneWidget,
      );

      // Tap Delete in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(mockService.deleteCalls, 1);
      expect(find.text('Contact deleted successfully.'), findsOneWidget);
      expect(find.text('Natasha Romanoff'), findsNothing);
    });
  });
}
