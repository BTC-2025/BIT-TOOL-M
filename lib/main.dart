import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:provider/provider.dart';

// Themes
import 'core/theme/app_theme.dart';

// Providers
import 'core/providers/auth_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/theme_provider.dart';

// Shell
import 'core/widgets/splash_screen.dart';

// Manage account token service for clean desktop state
import 'features/manage_account/core/network/token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}
  try {
    await TokenService.clearAll();
  } catch (_) {}
  runApp(const ProviderScope(child: BITToolApp()));
}

class BITToolApp extends StatelessWidget {
  const BITToolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initializeAuth()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) =>
              NotificationProvider(authProvider: context.read<AuthProvider>()),
          update: (_, auth, previous) =>
              (previous ?? NotificationProvider(authProvider: auth))
                ..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProxyProvider2<AuthProvider, SessionProvider, CalculatorProvider>(
          create: (context) => CalculatorProvider(
            context.read<SessionProvider>(),
            null,
            context.read<AuthProvider>(),
          ),
          update: (_, auth, session, previous) =>
              (previous ?? CalculatorProvider(session))..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, SessionProvider, CalendarProvider>(
          create: (context) => CalendarProvider(
            context.read<SessionProvider>(),
            null,
            context.read<AuthProvider>(),
          ),
          update: (_, auth, session, previous) =>
              (previous ?? CalendarProvider(session))..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, SessionProvider, NotesProvider>(
          create: (context) => NotesProvider(
            context.read<SessionProvider>(),
            null,
            context.read<AuthProvider>(),
          ),
          update: (_, auth, session, previous) =>
              (previous ?? NotesProvider(session))..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, SessionProvider, ContactsProvider>(
          create: (context) => ContactsProvider(
            context.read<SessionProvider>(),
            null,
            context.read<AuthProvider>(),
          ),
          update: (_, auth, session, previous) =>
              (previous ?? ContactsProvider(session))..updateAuth(auth),
        ),
        ChangeNotifierProvider(create: (_) => CurrencyConverterProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Bit tool',
            debugShowCheckedModeBanner: false,
            theme: NeumorphicTheme.lightTheme,
            darkTheme: NeumorphicTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
