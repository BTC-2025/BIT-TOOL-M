import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/core/widgets/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders BIT Tool logo as first image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          duration: Duration(seconds: 10),
          nextScreen: Scaffold(body: Text('Loaded Screen')),
        ),
      ),
    );
    await tester.pump();

    // Verify BIT TOOL branding is shown initially
    expect(find.text('BIT TOOL'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('SplashScreen renders subtitle and loading indicator on mobile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          duration: Duration(seconds: 10),
          nextScreen: Scaffold(body: Text('Loaded Screen')),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('BIT TOOL'), findsOneWidget);
    expect(find.text('Integrated Enterprise Suite'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('SplashScreen renders without overflow on narrow 320px mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          duration: Duration(seconds: 10),
          nextScreen: Scaffold(body: Text('Loaded Screen')),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('BIT TOOL'), findsOneWidget);
    expect(find.text('Integrated Enterprise Suite'), findsOneWidget);
  });

  testWidgets('SplashScreen handles large text scaling gracefully without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 2.0, 640 * 2.0);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: SplashScreen(
            duration: Duration(seconds: 10),
            nextScreen: Scaffold(body: Text('Loaded Screen')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('BIT TOOL'), findsOneWidget);
  });

  testWidgets('SplashScreen transitions to nextScreen after duration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          duration: Duration(milliseconds: 500),
          nextScreen: Scaffold(body: Text('Destination Screen')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('BIT TOOL'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    expect(find.text('Destination Screen'), findsOneWidget);
  });

  testWidgets('SplashScreen on macOS renders desktop layout', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            duration: Duration(seconds: 10),
            nextScreen: Scaffold(body: Text('Loaded Screen')),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('BIT TOOL'), findsOneWidget);
      expect(find.text('Integrated Enterprise Suite'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
