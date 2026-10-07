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
}
