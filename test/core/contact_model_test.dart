import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/contact_model.dart';

void main() {
  group('ContactModel Tests', () {
    test('parseFullName handles various name configurations accurately', () {
      expect(ContactModel.parseFullName(''), ('', ''));
      expect(ContactModel.parseFullName('   '), ('', ''));
      expect(ContactModel.parseFullName('Alice'), ('Alice', ''));
      expect(ContactModel.parseFullName('John Doe'), ('John', 'Doe'));
      expect(
        ContactModel.parseFullName('John Michael Doe'),
        ('John', 'Michael Doe'),
      );
      expect(
        ContactModel.parseFullName('  Dr.  Jane   Smith-Jones  '),
        ('Dr.', 'Jane Smith-Jones'),
      );
    });

    test('fullName and initial are computed correctly', () {
      const c1 = ContactModel(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
      );
      expect(c1.fullName, 'John Doe');
      expect(c1.initial, 'J');

      const c2 = ContactModel(
        id: '2',
        firstName: 'Alice',
      );
      expect(c2.fullName, 'Alice');
      expect(c2.initial, 'A');

      const c3 = ContactModel(
        id: '3',
        email: 'test@example.com',
      );
      expect(c3.fullName, 'test@example.com');
      expect(c3.initial, 'T');

      const c4 = ContactModel(id: '4');
      expect(c4.fullName, 'Unnamed Contact');
      expect(c4.initial, '?');
    });

    test('fromJson parses full backend schema correctly', () {
      final json = {
        'id': '101',
        'firstName': 'Arthur',
        'lastName': 'Dent',
        'email': 'arthur@galaxy.org',
        'phone': '+44 1234 567890',
        'company': 'BBC Radio',
        'notes': 'Prefers tea',
        'role': 'Broadcaster',
        'department': 'Media',
        'location': 'Earth',
        'photoUrl': 'https://example.com/avatar.png',
        'isFavorite': true,
        'isBlocked': false,
        'createdAt': '2026-05-01T12:00:00.000Z',
        'updatedAt': '2026-05-02T14:30:00.000Z',
      };

      final contact = ContactModel.fromJson(json);

      expect(contact.id, '101');
      expect(contact.firstName, 'Arthur');
      expect(contact.lastName, 'Dent');
      expect(contact.fullName, 'Arthur Dent');
      expect(contact.email, 'arthur@galaxy.org');
      expect(contact.phone, '+44 1234 567890');
      expect(contact.company, 'BBC Radio');
      expect(contact.notes, 'Prefers tea');
      expect(contact.role, 'Broadcaster');
      expect(contact.department, 'Media');
      expect(contact.isFavorite, isTrue);
      expect(contact.isBlocked, isFalse);
      expect(contact.createdAt, isNotNull);
      expect(contact.updatedAt, isNotNull);
    });

    test('fromJson handles numeric IDs and fallback full name', () {
      final json = {
        'id': 42,
        'name': 'Ford Prefect',
        'companyName': 'Sub-Etha',
        'phoneNumber': '9999999',
      };

      final contact = ContactModel.fromJson(json);

      expect(contact.id, '42');
      expect(contact.firstName, 'Ford');
      expect(contact.lastName, 'Prefect');
      expect(contact.fullName, 'Ford Prefect');
      expect(contact.company, 'Sub-Etha');
      expect(contact.phone, '9999999');
    });

    test('toApiBody serializes into documented contract schema', () {
      const contact = ContactModel(
        id: '1',
        firstName: ' Trillian ',
        lastName: ' Astra ',
        email: ' trillian@ship.org ',
        phone: ' 12345 ',
        company: ' Heart of Gold ',
        notes: ' Mathematician ',
      );

      final body = contact.toApiBody();

      expect(body, {
        'firstName': 'Trillian',
        'lastName': 'Astra',
        'email': 'trillian@ship.org',
        'phone': '12345',
        'company': 'Heart of Gold',
        'notes': 'Mathematician',
      });
    });

    test('fromJson parses real backend contact representation with phonenumber and role', () {
      final json = {
        'id': '215052d5-2832-4968-8e17-85315022c6ae',
        'userEmail': 'ravinew2004@bnxmail.com',
        'applicationName': 'BNX Mail',
        'externalId': null,
        'name': 'ashwin',
        'phonenumber': 'sddsfsdfadsfa',
        'email': 'ashwin@bnxmail.com',
        'role': 'colleague',
        'createdAt': '2026-08-13T12:12:05.955Z',
        'updatedAt': '2026-08-13T12:12:05.955Z',
        'deletedAt': null,
      };

      final contact = ContactModel.fromJson(json);

      expect(contact.id, '215052d5-2832-4968-8e17-85315022c6ae');
      expect(contact.fullName, 'ashwin');
      expect(contact.email, 'ashwin@bnxmail.com');
      expect(contact.phone, 'sddsfsdfadsfa');
      expect(contact.role, 'colleague');
      expect(contact.company, isEmpty);
      expect(contact.notes, isEmpty);
      expect(contact.createdAt, isNotNull);
      expect(contact.updatedAt, isNotNull);
    });

    test('fromJson safely handles null and literal "null" strings without displaying "null"', () {
      final json = {
        'id': 'uuid-123',
        'name': 'null',
        'email': 'null',
        'phone': null,
        'phoneNumber': 'null',
        'phonenumber': null,
        'company': 'null',
        'notes': null,
        'role': 'null',
        'department': null,
        'location': 'null',
        'photoUrl': null,
      };

      final contact = ContactModel.fromJson(json);

      expect(contact.id, 'uuid-123');
      expect(contact.firstName, '');
      expect(contact.lastName, '');
      expect(contact.fullName, 'Unnamed Contact');
      expect(contact.email, '');
      expect(contact.phone, '');
      expect(contact.company, '');
      expect(contact.notes, '');
      expect(contact.role, '');
      expect(contact.department, '');
      expect(contact.location, '');
      expect(contact.photoUrl, '');
    });

    test('toBackendBody serializes into verified backend schema', () {
      const contact = ContactModel(
        id: '1',
        firstName: 'Ashwin',
        lastName: 'Kumar',
        email: 'ashwin@bnxmail.com',
        phone: '1234567890',
        role: 'colleague',
      );

      final body = contact.toBackendBody();

      expect(body, {
        'name': 'Ashwin Kumar',
        'email': 'ashwin@bnxmail.com',
        'phonenumber': '1234567890',
        'role': 'colleague',
      });
    });

    test('copyWith updates properties correctly', () {
      const original = ContactModel(
        id: '1',
        firstName: 'Slartibartfast',
        lastName: 'Magrathea',
      );

      final updated = original.copyWith(
        email: 'fjords@magrathea.org',
        role: 'Coastline Designer',
      );

      expect(updated.id, '1');
      expect(updated.firstName, 'Slartibartfast');
      expect(updated.lastName, 'Magrathea');
      expect(updated.email, 'fjords@magrathea.org');
      expect(updated.role, 'Coastline Designer');
    });
  });

  group('ContactPagination Tests', () {
    test('fromJson parses metadata with calculated totalPages', () {
      final json = {
        'page': 2,
        'limit': 10,
        'total': 45,
        'totalPages': 5,
      };

      final pagination = ContactPagination.fromJson(json);

      expect(pagination.page, 2);
      expect(pagination.limit, 10);
      expect(pagination.total, 45);
      expect(pagination.totalPages, 5);
      expect(pagination.hasNextPage, isTrue);
      expect(pagination.hasPreviousPage, isTrue);
    });

    test('fromJson derives totalPages when missing in JSON', () {
      final json = {
        'currentPage': 1,
        'pageSize': 15,
        'totalRecords': 45,
      };

      final pagination = ContactPagination.fromJson(json);

      expect(pagination.page, 1);
      expect(pagination.limit, 15);
      expect(pagination.total, 45);
      expect(pagination.totalPages, 3);
      expect(pagination.hasNextPage, isTrue);
      expect(pagination.hasPreviousPage, isFalse);
    });
  });
}
