import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bit_tools_backend/core/api/api_client.dart';
import 'package:bit_tools_backend/core/auth/auth_storage.dart';
import 'package:bit_tools_backend/core/auth/auth_storage_io.dart';
import 'package:bit_tools_backend/core/providers/app_providers.dart';
import 'package:bit_tools_backend/core/providers/auth_provider.dart';
import 'package:bit_tools_backend/core/providers/notification_provider.dart';
import 'package:bit_tools_backend/core/providers/session_provider.dart';
import 'package:bit_tools_backend/core/providers/theme_provider.dart';
import 'package:bit_tools_backend/core/services/notification_api_service.dart';
import 'package:bit_tools_backend/core/widgets/responsive_shell.dart';

Widget _createTestApp({
  required NotificationProvider notificationProvider,
  required AuthProvider authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider.value(value: notificationProvider),
      ChangeNotifierProvider(create: (_) => SessionProvider()),
      ChangeNotifierProxyProvider<SessionProvider, CalculatorProvider>(
        create: (context) =>
            CalculatorProvider(context.read<SessionProvider>()),
        update: (_, session, previous) =>
            previous ?? CalculatorProvider(session),
      ),
      ChangeNotifierProxyProvider<SessionProvider, CalendarProvider>(
        create: (context) => CalendarProvider(context.read<SessionProvider>()),
        update: (_, session, previous) => previous ?? CalendarProvider(session),
      ),
      ChangeNotifierProxyProvider<SessionProvider, NotesProvider>(
        create: (context) => NotesProvider(context.read<SessionProvider>()),
        update: (_, session, previous) => previous ?? NotesProvider(session),
      ),
      ChangeNotifierProxyProvider<SessionProvider, ContactsProvider>(
        create: (context) => ContactsProvider(context.read<SessionProvider>()),
        update: (_, session, previous) => previous ?? ContactsProvider(session),
      ),
    ],
    child: const MaterialApp(home: ResponsiveShell()),
  );
}

void main() {
  group('Notifications Panel & Bell Widget Tests', () {
    late AuthStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = AuthStorageIo();
    });

    testWidgets(
      'renders bell icon and displays unread count badge when unread > 0',
      (WidgetTester tester) async {
        await storage.saveToken('VALID_TOKEN');

        const sampleNotifications = '''
      [
        {"id": "1", "title": "First", "message": "Msg 1", "isRead": false},
        {"id": "2", "title": "Second", "message": "Msg 2", "isRead": true}
      ]
      ''';

        final mockClient = MockClient((request) async {
          return http.Response(sampleNotifications, 200);
        });

        final notifService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );
        final notifProvider = NotificationProvider(apiService: notifService);
        await notifProvider.fetchNotifications();

        final authProvider = AuthProvider(authStorage: storage);

        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _createTestApp(
            notificationProvider: notifProvider,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Verify unread badge is 1
        expect(
          find.descendant(of: find.byType(Badge), matching: find.text('1')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'opening panel displays loaded items and mark single as read works',
      (WidgetTester tester) async {
        await storage.saveToken('VALID_TOKEN');

        const sampleNotifications = '''
      [
        {"id": "item-1", "title": "Weather alert", "message": "Rain incoming", "isRead": false, "type": "weather"}
      ]
      ''';

        final mockClient = MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/notifications')) {
            return http.Response(sampleNotifications, 200);
          }
          if (request.method == 'PUT' &&
              request.url.path.endsWith('/notifications/item-1/read')) {
            return http.Response(
              '{"status": "success", "message": "read"}',
              200,
            );
          }
          return http.Response('Error', 400);
        });

        final notifService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );
        final notifProvider = NotificationProvider(apiService: notifService);
        await notifProvider.fetchNotifications();

        final authProvider = AuthProvider(authStorage: storage);

        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _createTestApp(
            notificationProvider: notifProvider,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Tap on bell icon
        final bellFinder = find.byTooltip('Notifications');
        expect(bellFinder, findsOneWidget);
        await tester.tap(bellFinder);
        await tester.pumpAndSettle();

        // Notifications panel is open
        expect(find.text('Notifications'), findsWidgets);
        expect(find.text('Weather alert'), findsOneWidget);
        expect(find.text('Rain incoming'), findsOneWidget);

        // Tap the notification item to mark as read
        await tester.tap(find.text('Weather alert'));
        await tester.pumpAndSettle();

        // State is updated
        expect(notifProvider.unreadCount, 0);
      },
    );

    testWidgets(
      'displays "All caught up!" and "No new notifications" on empty list',
      (WidgetTester tester) async {
        await storage.saveToken('VALID_TOKEN');

        final mockClient = MockClient((request) async {
          return http.Response('[]', 200);
        });

        final notifService = NotificationApiService(
          apiClient: ApiClient(client: mockClient),
          authStorage: storage,
        );
        final notifProvider = NotificationProvider(apiService: notifService);
        await notifProvider.fetchNotifications();

        final authProvider = AuthProvider(authStorage: storage);

        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _createTestApp(
            notificationProvider: notifProvider,
            authProvider: authProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Tap bell
        await tester.tap(find.byTooltip('Notifications'));
        await tester.pumpAndSettle();

        // Empty state verification
        expect(find.text('All caught up!'), findsOneWidget);
        expect(find.text('No new notifications'), findsOneWidget);
      },
    );

    testWidgets('displays error state and Retry button on failure', (
      WidgetTester tester,
    ) async {
      await storage.saveToken('VALID_TOKEN');

      var fail = true;
      final mockClient = MockClient((request) async {
        if (fail) {
          return http.Response('Server error', 500);
        }
        return http.Response('[]', 200);
      });

      final notifService = NotificationApiService(
        apiClient: ApiClient(client: mockClient),
        authStorage: storage,
      );
      final notifProvider = NotificationProvider(apiService: notifService);
      await notifProvider.fetchNotifications();

      final authProvider = AuthProvider(authStorage: storage);

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _createTestApp(
          notificationProvider: notifProvider,
          authProvider: authProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Tap bell
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();

      // Error state verification
      expect(find.text('Retry'), findsOneWidget);

      // Now set fail = false and tap Retry
      fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Now successfully loaded empty state
      expect(find.text('All caught up!'), findsOneWidget);
    });
  });
}
