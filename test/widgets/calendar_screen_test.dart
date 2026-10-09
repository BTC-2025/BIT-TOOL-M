import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bit_tools_backend/core/models/calendar_models.dart';
import 'package:bit_tools_backend/core/providers/calendar_provider.dart';
import 'package:bit_tools_backend/features/calendar/calendar_screen.dart';
import '../providers/calendar_provider_test.dart';

Widget _buildTestApp({required CalendarProvider calendarProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CalendarProvider>.value(
        value: calendarProvider,
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: CalendarScreen(),
      ),
    ),
  );
}

void main() {
  group('CalendarScreen Widget Tests', () {
    late FakeCalendarApiService fakeService;
    late FakeAuthProvider fakeAuth;
    late CalendarProvider provider;

    setUp(() {
      fakeService = FakeCalendarApiService();
      fakeAuth = FakeAuthProvider();

      fakeService.mockCategories = [
        const CalendarCategory(id: 'cat-1', name: 'Work', color: '#2563EB'),
        const CalendarCategory(id: 'cat-2', name: 'Personal', color: '#10B981'),
      ];

      provider = CalendarProvider(
        null,
        fakeService,
        fakeAuth,
      );
    });

    testWidgets('renders month header, day labels, and dynamic calendar leaves',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(calendarProvider: provider));
      await tester.pumpAndSettle();

      // Check header month
      expect(find.textContaining('2026'), findsWidgets);

      // Check day columns
      expect(find.text('SUN'), findsOneWidget);
      expect(find.text('MON'), findsOneWidget);
      expect(find.text('WED'), findsOneWidget);

      // Dynamic leaves: in October 2026, Columbus Day and Halloween are dynamically calculated
      expect(find.text('Columbus Day'), findsOneWidget);
      expect(find.text('Halloween'), findsOneWidget);
    });

    testWidgets('renders real events on corresponding day cells', (tester) async {
      final today = provider.selectedDate;
      fakeService.mockEvents = [
        CalendarEvent(
          id: 'evt-1',
          title: 'Design Standup',
          startTime: DateTime(today.year, today.month, today.day, 10, 0),
          endTime: DateTime(today.year, today.month, today.day, 11, 0),
          categoryId: 'cat-1',
          categoryModel: const CalendarCategory(id: 'cat-1', name: 'Work', color: '#2563EB'),
        ),
      ];

      await provider.fetchMonthEvents();

      await tester.pumpWidget(_buildTestApp(calendarProvider: provider));
      await tester.pumpAndSettle();

      expect(find.textContaining('Design Standup'), findsOneWidget);
    });

    testWidgets('tapping event opens edit event dialog with delete button', (tester) async {
      final today = provider.selectedDate;
      fakeService.mockEvents = [
        CalendarEvent(
          id: 'evt-edit',
          title: 'Quarterly Planning',
          description: 'Discuss H2 goals',
          startTime: DateTime(today.year, today.month, today.day, 13, 30),
          endTime: DateTime(today.year, today.month, today.day, 16, 30),
        ),
      ];

      await provider.fetchMonthEvents();

      await tester.pumpWidget(_buildTestApp(calendarProvider: provider));
      await tester.pumpAndSettle();

      final eventChip = find.textContaining('Quarterly Planning');
      expect(eventChip, findsOneWidget);

      await tester.tap(eventChip);
      await tester.pumpAndSettle();

      // Verify Image 2 Edit Event dialog elements
      expect(find.text('Edit Event'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Quarterly Planning'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Save event'), findsOneWidget);
    });

    testWidgets('navigating next month updates displayed header', (tester) async {
      await tester.pumpWidget(_buildTestApp(calendarProvider: provider));
      await tester.pumpAndSettle();

      // Find the ChevronRight icon button to advance month
      final nextButton = find.byIcon(Icons.chevron_right_rounded);
      expect(nextButton, findsOneWidget);

      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(fakeService.getMonthEventsCalls, greaterThanOrEqualTo(2));
    });

    testWidgets('search field triggers search and displays search results view', (tester) async {
      fakeService.mockSearchResult = CalendarSearchResult(
        events: [
          CalendarEvent(
            id: 'evt-search-hit',
            title: 'Budget Allocation Review',
            startTime: DateTime(2026, 10, 9, 15, 0),
            endTime: DateTime(2026, 10, 9, 16, 0),
          ),
        ],
        notes: const [
          CalendarDateNote(
            id: 'note-search-hit',
            title: 'Budget Brainstorm',
            date: '2026-10-09',
            content: 'Line items reviewed',
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(calendarProvider: provider));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Budget');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Budget Allocation Review'), findsOneWidget);
      expect(find.text('Budget Brainstorm'), findsOneWidget);
    });

    testWidgets('add event icon (+) displays Create New Item dialog matching design', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(calendarProvider: provider));
      await tester.pumpAndSettle();

      final addIcons = find.byIcon(Icons.add_rounded);
      expect(addIcons, findsWidgets);

      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      expect(find.text('Create New Item'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Reminder'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.text('Category (Optional)'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Save event'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);

      // Switch to Note tab (Image 2)
      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Save note'), findsOneWidget);

      // Switch to Reminder tab (Image 3)
      await tester.tap(find.text('Reminder'));
      await tester.pumpAndSettle();
      expect(find.text('Reminder Time'), findsOneWidget);
      expect(find.text('Save reminder'), findsOneWidget);
    });

    testWidgets('tapping date cell opens Date Overview dialog with Add New Item button', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildTestApp(calendarProvider: provider));
      await tester.pumpAndSettle();

      // Tap on day cell 14
      final day14 = find.text('14');
      expect(day14, findsOneWidget);

      await tester.tap(day14);
      await tester.pumpAndSettle();

      // Image 5 Date Overview dialog
      expect(find.textContaining('14 October 2026'), findsOneWidget);
      expect(find.text('EVENTS'), findsOneWidget);
      expect(find.text('Add New Item'), findsOneWidget);

      // Tapping "Add New Item" opens Create New Item dialog
      await tester.tap(find.text('Add New Item'));
      await tester.pumpAndSettle();

      expect(find.text('Create New Item'), findsOneWidget);
    });

    testWidgets('allows manually typing new category and excludes red options', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeService.mockCategories = [
        const CalendarCategory(id: 'cat-red', name: 'red', color: '#EF4444'),
        const CalendarCategory(id: 'cat-work', name: 'Work', color: '#2563EB'),
      ];
      await provider.fetchCategories();

      await tester.pumpWidget(_buildTestApp(calendarProvider: provider));
      await tester.pumpAndSettle();

      // Open Create New Item dialog
      final addIcons = find.byIcon(Icons.add_rounded);
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      // Tap on Category (Optional) dropdown
      final categoryDropdown = find.text('Category (Optional)');
      expect(categoryDropdown, findsOneWidget);

      final categorySelectorButton = find.text('No Category');
      expect(categorySelectorButton, findsOneWidget);
      await tester.tap(categorySelectorButton);
      await tester.pumpAndSettle();

      // Options like 'red' should NOT be present in dropdown options
      expect(find.text('red'), findsNothing);
      expect(find.text('Work'), findsOneWidget);

      // Tap + Add New Category
      final addNewCategoryItem = find.text('Add New Category');
      expect(addNewCategoryItem, findsOneWidget);
      await tester.tap(addNewCategoryItem);
      await tester.pumpAndSettle();

      // Input field for manually typing new category should appear
      final inputField = find.byType(TextField).last;
      await tester.enterText(inputField, 'Design Team');
      await tester.pumpAndSettle();

      // Tap Add button
      final addButton = find.widgetWithText(ElevatedButton, 'Add');
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Category should now be selected and displayed
      expect(find.text('Design Team'), findsOneWidget);
    });
  });
}
