import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';

void main() {
  group('UserModel & OrganizationModel Tests', () {
    test('parses full user payload correctly', () {
      final json = {
        'id': 28,
        'email': 'user@example.com',
        'firstName': 'First',
        'lastName': 'Last',
        'fullName': 'First Last',
        'profilePictureUrl': 'https://example.com/avatar.png',
        'role': 'ORG_ADMIN',
        'accountType': 'BUSINESS',
        'storageUsed': 0,
        'storageLimit': 16106127360,
        'isPrimary': true,
        'phoneNumber': '+1234567890',
        'recoveryEmail': 'recovery@example.com',
        'dob': '1990-01-01',
        'organization': {'id': 6, 'name': 'Organization Name'},
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 28);
      expect(user.email, 'user@example.com');
      expect(user.firstName, 'First');
      expect(user.lastName, 'Last');
      expect(user.fullName, 'First Last');
      expect(user.profilePictureUrl, 'https://example.com/avatar.png');
      expect(user.role, 'ORG_ADMIN');
      expect(user.accountType, 'BUSINESS');
      expect(user.storageUsed, 0);
      expect(user.storageLimit, 16106127360);
      expect(user.isPrimary, true);
      expect(user.phoneNumber, '+1234567890');
      expect(user.recoveryEmail, 'recovery@example.com');
      expect(user.dob, '1990-01-01');
      expect(user.organization, isNotNull);
      expect(user.organization!.id, 6);
      expect(user.organization!.name, 'Organization Name');
      expect(user.displayName, 'First Last');
      expect(user.initials, 'FL');
      expect(user.hasValidProfilePicture, true);
    });

    test('TEST 7: safely parses null optional fields without crashing', () {
      final json = {
        'id': 42,
        'email': 'ravi@bnxmail.com',
        'firstName': null,
        'lastName': null,
        'fullName': null,
        'profilePictureUrl': null,
        'role': 'MEMBER',
        'accountType': null,
        'storageUsed': null,
        'storageLimit': null,
        'isPrimary': false,
        'phoneNumber': null,
        'recoveryEmail': null,
        'dob': null,
        'organization': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 42);
      expect(user.email, 'ravi@bnxmail.com');
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
      expect(user.fullName, isNull);
      expect(user.profilePictureUrl, isNull);
      expect(user.phoneNumber, isNull);
      expect(user.recoveryEmail, isNull);
      expect(user.dob, isNull);
      expect(user.organization, isNull);
      expect(user.displayName, 'ravi');
      expect(user.initials, 'R');
      expect(user.hasValidProfilePicture, false);
      expect(user.displayName.contains('null'), false);
    });

    test(
      'fallback initials works when only firstName and lastName are provided',
      () {
        const user = UserModel(
          id: 1,
          email: 'john@example.com',
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(user.displayName, 'John Doe');
        expect(user.initials, 'JD');
      },
    );

    test('fallback initials works with single name', () {
      const user = UserModel(
        id: 2,
        email: 'alice@example.com',
        fullName: 'Alice',
      );

      expect(user.displayName, 'Alice');
      expect(user.initials, 'A');
    });

    test('toJson and equality work symmetrically', () {
      const user1 = UserModel(
        id: 10,
        email: 'test@example.com',
        fullName: 'Test User',
      );
      final json = user1.toJson();
      final user2 = UserModel.fromJson(json);

      expect(user1, equals(user2));
    });

    test('parses alternative photo/avatar keys and resolves relative URL', () {
      final json = {
        'id': 99,
        'email': 'photo@example.com',
        'avatarUrl': '/uploads/photo99.png',
      };
      final user = UserModel.fromJson(json);

      expect(user.profilePictureUrl, '/uploads/photo99.png');
      expect(user.hasValidProfilePicture, isTrue);
      expect(
        user.resolvedProfilePictureUrl,
        'https://api.bnxmail.com/uploads/photo99.png',
      );
    });
  });
}
