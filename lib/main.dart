import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Themes
import 'core/theme/app_theme.dart';

// Providers
import 'core/providers/session_provider.dart';
import 'core/providers/app_providers.dart';

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
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProxyProvider<SessionProvider, MailProvider>(
          create: (context) => MailProvider(context.read<SessionProvider>()),
          update: (_, session, previous) => previous ?? MailProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, CalendarProvider>(
          create: (context) =>
              CalendarProvider(context.read<SessionProvider>()),
          update: (_, session, previous) =>
              previous ?? CalendarProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, CalculatorProvider>(
          create: (context) =>
              CalculatorProvider(context.read<SessionProvider>()),
          update: (_, session, previous) =>
              previous ?? CalculatorProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, ContactsProvider>(
          create: (context) =>
              ContactsProvider(context.read<SessionProvider>()),
          update: (_, session, previous) =>
              previous ?? ContactsProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, MessagesProvider>(
          create: (context) =>
              MessagesProvider(context.read<SessionProvider>()),
          update: (_, session, previous) =>
              previous ?? MessagesProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, AuthProvider>(
          create: (context) => AuthProvider(context.read<SessionProvider>()),
          update: (_, session, previous) => previous ?? AuthProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, DevicesProvider>(
          create: (context) => DevicesProvider(context.read<SessionProvider>()),
          update: (_, session, previous) =>
              previous ?? DevicesProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, FilesProvider>(
          create: (context) => FilesProvider(context.read<SessionProvider>()),
          update: (_, session, previous) => previous ?? FilesProvider(session),
        ),
        ChangeNotifierProxyProvider<SessionProvider, ReportsProvider>(
          create: (context) => ReportsProvider(context.read<SessionProvider>()),
          update: (_, session, previous) =>
              previous ?? ReportsProvider(session),
        ),
      ],
      child: MaterialApp(
        title: 'BIT Tool',
        debugShowCheckedModeBanner: false,
        theme: NeumorphicTheme.lightTheme,
        darkTheme: NeumorphicTheme.darkTheme,
        themeMode: ThemeMode
            .light, // Handled internally by ResponsiveShell dynamic theme injection
        home: const SplashScreen(),
      ),
    );
  }
}
