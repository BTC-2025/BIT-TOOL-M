import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/models/user_model.dart';
import 'package:bit_tools_backend/core/widgets/user_avatar.dart';

void main() {
  group('UserAvatar Widget Tests', () {
    testWidgets(
      'TEST 5: renders network image when profilePictureUrl is valid',
      (WidgetTester tester) async {
        const user = UserModel(
          id: 1,
          email: 'user@example.com',
          fullName: 'Jane Doe',
          profilePictureUrl: 'https://example.com/jane.png',
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: UserAvatar(user: user, radius: 24)),
          ),
        );

        // Verify Image is present
        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets(
      'TEST 6: renders initials in fallback avatar when profilePictureUrl is null',
      (WidgetTester tester) async {
        const user = UserModel(
          id: 2,
          email: 'user@example.com',
          firstName: 'Ravi',
          lastName: 'Kumar',
          profilePictureUrl: null,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: UserAvatar(user: user, radius: 24)),
          ),
        );

        // Verify no network Image widget was built
        expect(find.byType(Image), findsNothing);
        // Verify CircleAvatar with initial 'RK' is rendered
        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.text('RK'), findsOneWidget);
      },
    );

    testWidgets('gracefully renders default initial when user is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UserAvatar(user: null, radius: 20)),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
    });

    testWidgets('renders image when profilePictureUrl is a relative path', (
      WidgetTester tester,
    ) async {
      const user = UserModel(
        id: 3,
        email: 'user@example.com',
        fullName: 'Jane Doe',
        profilePictureUrl: '/uploads/avatars/user3.jpg',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UserAvatar(user: user, radius: 24)),
        ),
      );

      expect(user.resolvedProfilePictureUrl, 'https://api.bnxmail.com/uploads/avatars/user3.jpg');
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders image when profilePictureUrl is a base64 data URI', (
      WidgetTester tester,
    ) async {
      // 1x1 transparent PNG base64
      const base64Png =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      const user = UserModel(
        id: 4,
        email: 'user@example.com',
        fullName: 'Jane Doe',
        profilePictureUrl: base64Png,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UserAvatar(user: user, radius: 24)),
        ),
      );

      expect(user.hasValidProfilePicture, isTrue);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
