import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/features/keyboard/keyboard_screen.dart';

void main() {
  group('KeyboardScreen Widget Tests', () {
    testWidgets(
      'renders title, copy button, input field and on-screen keyboard',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: KeyboardScreen())),
        );
        await tester.pumpAndSettle();

        // Verify title and copy button
        expect(find.text('Keyboard'), findsOneWidget);
        expect(find.text('Copy Text'), findsOneWidget);

        // Verify initial empty textfield
        expect(find.text('Type here...'), findsOneWidget);

        // Verify letters row 1 exists
        expect(find.text('q'), findsOneWidget);
        expect(find.text('w'), findsOneWidget);
        expect(find.text('p'), findsOneWidget);

        // Verify space and return keys
        expect(find.text('space'), findsOneWidget);
        expect(find.text('return'), findsOneWidget);
      },
    );

    testWidgets('tapping keys updates text in input field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: KeyboardScreen())),
      );
      await tester.pumpAndSettle();

      // Tap 'h'
      await tester.tap(find.text('h'));
      await tester.pumpAndSettle();

      // Tap 'i'
      await tester.tap(find.text('i'));
      await tester.pumpAndSettle();

      // Tap 'space'
      await tester.tap(find.text('space'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('hi '));

      // Tap backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();

      expect(textField.controller?.text, equals('hi'));
    });

    testWidgets('toggling 123 mode switches keys and back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: KeyboardScreen())),
      );
      await tester.pumpAndSettle();

      // Tap 123
      await tester.tap(find.text('123'));
      await tester.pumpAndSettle();

      // Numbers should be visible
      expect(find.text('1'), findsOneWidget);
      expect(find.text('ABC'), findsOneWidget);

      // Tap ABC to toggle back
      await tester.tap(find.text('ABC'));
      await tester.pumpAndSettle();

      expect(find.text('q'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
    });
  });
}
