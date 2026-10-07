import 'package:flutter_test/flutter_test.dart';
import 'package:bit_tools_backend/main.dart';

void main() {
  testWidgets('BITToolApp smoke test loads and renders Home app bar title', (
    WidgetTester tester,
  ) async {
    // Build the BITToolApp and trigger a frame.
    await tester.pumpWidget(const BITToolApp());
    await tester.pumpAndSettle();

    // Verify initial Home screen title is displayed
    expect(find.text('Home'), findsWidgets);
  });
}
