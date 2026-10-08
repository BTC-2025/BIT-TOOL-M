import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/api/api_config.dart';
import 'package:bit_tools_backend/core/api/api_exceptions.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/services/user_api_service.dart';
import 'package:bit_tools_backend/features/auth/sign_in_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserApiService Login Tests', () {
    test('login success saves token and retrieves current user profile', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Login successful',
              'data': {'token': 'valid_jwt_token_123'},
            }),
            200,
          );
        } else if (request.url.path == '/api/users/me') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'User retrieved successfully',
              'data': {
                'id': 'usr_1',
                'name': 'John Doe',
                'email': 'john@bnxmail.com',
                'role': 'user',
                'organizations': [],
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final storage = AuthStorage();
      final apiClient = ApiClient(client: mockClient);
      final service = UserApiService(
        apiClient: apiClient,
        authStorage: storage,
      );

      final user = await service.login(
        email: 'john@bnxmail.com',
        password: 'password123',
      );

      expect(user.displayName, 'John Doe');
      expect(user.email, 'john@bnxmail.com');
      final savedToken = await storage.getToken();
      expect(savedToken, 'valid_jwt_token_123');
    });

    test('login failure on invalid credentials throws InvalidCredentialsException', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Invalid credentials',
              'data': null,
            }),
            400,
          );
        }
        return http.Response('Not Found', 404);
      });

      final storage = AuthStorage();
      final apiClient = ApiClient(client: mockClient);
      final service = UserApiService(
        apiClient: apiClient,
        authStorage: storage,
      );

      expect(
        () => service.login(
          email: 'wrong@bnxmail.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });
  });

  group('AuthProvider SignIn Workflow Tests', () {
    test('signIn with invalid credentials sets Invalid Credentials error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid credentials',
            'data': null,
          }),
          400,
        );
      });

      final storage = AuthStorage();
      final apiClient = ApiClient(client: mockClient);
      final service = UserApiService(apiClient: apiClient, authStorage: storage);
      final authProvider = AuthProvider(
        authStorage: storage,
        userApiService: service,
      );

      final success = await authProvider.signIn(
        email: 'wrong@bnxmail.com',
        password: 'badpass',
      );

      expect(success, isFalse);
      expect(authProvider.status, AuthStatus.authenticationError);
      expect(authProvider.errorMessage, 'Invalid Credentials');
      expect(authProvider.user, isNull);
    });

    test('signIn with valid credentials succeeds and populates user', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Login successful',
              'data': {'token': 'valid_jwt_token_456'},
            }),
            200,
          );
        } else if (request.url.path == '/api/users/me') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'User retrieved successfully',
              'data': {
                'id': 'usr_2',
                'name': 'Alice Smith',
                'email': 'alice@bnxmail.com',
                'role': 'admin',
                'organizations': [],
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final storage = AuthStorage();
      final apiClient = ApiClient(client: mockClient);
      final service = UserApiService(apiClient: apiClient, authStorage: storage);
      final authProvider = AuthProvider(
        authStorage: storage,
        userApiService: service,
      );

      final success = await authProvider.signIn(
        email: 'alice@bnxmail.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.user?.displayName, 'Alice Smith');
    });
  });

  group('SignInScreen Widget Tests', () {
    testWidgets('renders B2Auth Sign In UI elements correctly', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('{"status": "ok"}', 200);
      });
      final storage = AuthStorage();
      final apiClient = ApiClient(client: mockClient);
      final service = UserApiService(apiClient: apiClient, authStorage: storage);
      final authProvider = AuthProvider(
        authStorage: storage,
        userApiService: service,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const SignInScreen(),
          ),
        ),
      );

      expect(find.text('Sign in to B2Auth'), findsOneWidget);
      expect(find.text('Use your BETA Account'), findsOneWidget);
      expect(find.text('Email:'), findsOneWidget);
      expect(find.text('Enter email address'), findsOneWidget);
      expect(find.text('Password:'), findsOneWidget);
      expect(find.text('Enter password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign in with a saved account'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Report Issue'), findsOneWidget);
    });

    testWidgets('shows Invalid Credentials when invalid credentials entered', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Invalid credentials',
            'data': null,
          }),
          400,
        );
      });
      final storage = AuthStorage();
      final apiClient = ApiClient(client: mockClient);
      final service = UserApiService(apiClient: apiClient, authStorage: storage);
      final authProvider = AuthProvider(
        authStorage: storage,
        userApiService: service,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const SignInScreen(),
          ),
        ),
      );

      // Enter wrong credentials
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter email address'),
        'wrong@bnxmail.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter password'),
        'wrongpassword',
      );

      // Tap Login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Verify "Invalid Credentials" is shown
      expect(find.text('Invalid Credentials'), findsOneWidget);
    });
  });
}
