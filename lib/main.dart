import 'package:flutter/material.dart';
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

void main() {
  runApp(const BITToolApp());
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
        ChangeNotifierProxyProvider<SessionProvider, CalculatorProvider>(
          create: (context) =>
              CalculatorProvider(context.read<SessionProvider>()),
          update: (_, session, previous) =>
              previous ?? CalculatorProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, CalendarProvider>(
          create: (context) =>
              CalendarProvider(context.read<SessionProvider>()),
          update: (_, session, previous) =>
              previous ?? CalendarProvider(session),
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
