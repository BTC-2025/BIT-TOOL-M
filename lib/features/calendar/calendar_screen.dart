import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/calendar_models.dart';
import '../../core/providers/calendar_provider.dart';

enum CreateItemTab { event, note, reminder }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  String _selectedAppFilter = 'All Apps';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _appFilters = [
    'All Apps',
    'Bit Tool',
    'Cliks',
    'Cliks Business',
    'BNX Mail',
  ];

  static const List<String> _weekDays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _fullWeekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CalendarProvider>();
      if (provider.status == CalendarStatus.initial) {
        provider.fetchInitialData();
      } else if (!provider.isLoading) {
        provider.fetchMonthEvents();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final provider = context.read<CalendarProvider>();
      if (!provider.isLoading) {
        provider.fetchMonthEvents();
      }
    }
  }

  Color _parseColor(String? colorStr, [Color fallback = const Color(0xFF2563EB)]) {
    if (colorStr == null || colorStr.trim().isEmpty) return fallback;
    var hex = colorStr.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final val = int.tryParse(hex, radix: 16);
    if (val != null) return Color(val);
    return fallback;
  }

  String _formatTime12h(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minute $period';
  }

  String _formatDateOverviewTitle(DateTime date) {
    final dayName = _fullWeekDays[date.weekday - 1];
    final monthName = _months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  // ==========================================
  // Dialog: Date Overview (Matching Image 5)
  // ==========================================

  void _showDateOverviewDialog(DateTime cellDate) {
    showDialog(
      context: context,
      builder: (overviewCtx) {
        return Consumer<CalendarProvider>(
          builder: (context, provider, _) {
            // Find events for this cell date
            final dayEvents = provider.events.where((e) {
              if (!e.matchesDate(cellDate)) return false;
              return e.matchesApp(_selectedAppFilter);
            }).toList();

            final dateFormatted = _formatDateOverviewTitle(cellDate);

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isDark ? BorderSide(color: borderColor) : BorderSide.none,
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Date + Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              dateFormatted,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(overviewCtx),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Section Header: EVENTS
                      Text(
                        'EVENTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // List of Events with Scroll Wrapper to prevent vertical overflow
                      if (dayEvents.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No events scheduled for this day',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: dayEvents.map((e) {
                                final timeStr =
                                    '${e.startTime.hour.toString().padLeft(2, '0')}:${e.startTime.minute.toString().padLeft(2, '0')}';

                                return InkWell(
                                  onTap: () {
                                    Navigator.pop(overviewCtx);
                                    _showEditEventDialog(e);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF1D4ED8).withValues(alpha: 0.4)
                                            : const Color(0xFFDBEAFE),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_rounded,
                                          size: 14,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$timeStr ${e.title}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? const Color(0xFF93C5FD)
                                                  : const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Add New Item Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text(
                            'Add New Item',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.pop(overviewCtx);
                            _showCreateItemDialog(initialDate: cellDate);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // Dialog: Create New Item (Matching Images 1, 2, 3, 4)
  // ==========================================

  void _showCreateItemDialog({
    DateTime? initialDate,
    CreateItemTab initialTab = CreateItemTab.event,
  }) {
    final provider = context.read<CalendarProvider>();
    CreateItemTab activeTab = initialTab;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final contentController = TextEditingController();

    final DateTime eventDate = initialDate ?? provider.selectedDate;

    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0); // 09:00 AM (Image 1)
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0); // 10:00 AM (Image 1)
    TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0); // 09:00 AM (Image 3)

    String? selectedCategoryId;
    bool isAddingCategory = false;
    final newCatNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isDark ? BorderSide(color: borderColor) : BorderSide.none,
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Title + Close Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Create New Item',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(dialogCtx),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Pill Segmented Tab Bar: Event | Note | Reminder
                        Container(
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildSegmentedTab(
                                label: 'Event',
                                isSelected: activeTab == CreateItemTab.event,
                                onTap: () => setDialogState(
                                  () => activeTab = CreateItemTab.event,
                                ),
                              ),
                              _buildSegmentedTab(
                                label: 'Note',
                                isSelected: activeTab == CreateItemTab.note,
                                onTap: () => setDialogState(
                                  () => activeTab = CreateItemTab.note,
                                ),
                              ),
                              _buildSegmentedTab(
                                label: 'Reminder',
                                isSelected: activeTab == CreateItemTab.reminder,
                                onTap: () => setDialogState(
                                  () => activeTab = CreateItemTab.reminder,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title Field
                        const Text(
                          'Title',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: '',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tab-Specific Content:
                        // ==========================================
                        // EVENT TAB (Image 1)
                        // ==========================================
                        if (activeTab == CreateItemTab.event) ...[
                          // Start Time and End Time Row
                          Row(
                            children: [
                              // Start Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start Time',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: startTime,
                                        );
                                        if (picked != null) {
                                          setDialogState(() => startTime = picked);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatTime12h(startTime),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 18,
                                              color: Color(0xFF64748B),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // End Time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'End Time',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: endTime,
                                        );
                                        if (picked != null) {
                                          setDialogState(() => endTime = picked);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatTime12h(endTime),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 18,
                                              color: Color(0xFF64748B),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Category Selector (with manual typing support, no red options)
                          _buildCategorySelector(
                            provider: provider,
                            selectedCategoryId: selectedCategoryId,
                            isAddingCategory: isAddingCategory,
                            newCatNameController: newCatNameController,
                            onAddingCategoryChanged: (adding) {
                              setDialogState(() => isAddingCategory = adding);
                            },
                            onCategorySelected: (catId) {
                              setDialogState(() => selectedCategoryId = catId);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Description Field
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descController,
                            maxLines: 4,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add details...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                        ]
                        // ==========================================
                        // NOTE TAB (Image 2)
                        // ==========================================
                        else if (activeTab == CreateItemTab.note) ...[
                          _buildCategorySelector(
                            provider: provider,
                            selectedCategoryId: selectedCategoryId,
                            isAddingCategory: isAddingCategory,
                            newCatNameController: newCatNameController,
                            onAddingCategoryChanged: (adding) {
                              setDialogState(() => isAddingCategory = adding);
                            },
                            onCategorySelected: (catId) {
                              setDialogState(() => selectedCategoryId = catId);
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Content',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: contentController,
                            maxLines: 5,
                            minLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Write your note here...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                        ]
                        // ==========================================
                        // REMINDER TAB (Image 3)
                        // ==========================================
                        else if (activeTab == CreateItemTab.reminder) ...[
                          // Reminder Time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reminder Time',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: reminderTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() => reminderTime = picked);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatTime12h(reminderTime),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 18,
                                        color: Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildCategorySelector(
                            provider: provider,
                            selectedCategoryId: selectedCategoryId,
                            isAddingCategory: isAddingCategory,
                            newCatNameController: newCatNameController,
                            onAddingCategoryChanged: (adding) {
                              setDialogState(() => isAddingCategory = adding);
                            },
                            onCategorySelected: (catId) {
                              setDialogState(() => selectedCategoryId = catId);
                            },
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descController,
                            maxLines: 4,
                            minLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add details...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Bottom Actions: Cancel & Save
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                if (titleController.text.trim().isEmpty) return;

                                try {
                                  if (activeTab == CreateItemTab.event) {
                                    String catId = selectedCategoryId ?? '';
                                    if (isAddingCategory &&
                                        newCatNameController.text.trim().isNotEmpty) {
                                      final createdCat =
                                          await provider.createCategory(
                                        name: newCatNameController.text.trim(),
                                        color: '#2563EB',
                                      );
                                      catId = createdCat.id;
                                    } else if (catId.isEmpty) {
                                      final validCats = provider.categories
                                          .where((c) =>
                                              c.name.trim().toLowerCase() != 'red')
                                          .toList();
                                      if (validCats.isEmpty) {
                                        final createdCat =
                                            await provider.createCategory(
                                          name: 'General',
                                          color: '#3B82F6',
                                        );
                                        catId = createdCat.id;
                                      } else {
                                        catId = validCats.first.id;
                                      }
                                    }

                                    final startDt = DateTime(
                                      eventDate.year,
                                      eventDate.month,
                                      eventDate.day,
                                      startTime.hour,
                                      startTime.minute,
                                    );
                                    final endDt = DateTime(
                                      eventDate.year,
                                      eventDate.month,
                                      eventDate.day,
                                      endTime.hour,
                                      endTime.minute,
                                    );

                                    await provider.createEvent(
                                      title: titleController.text.trim(),
                                      description: descController.text.trim(),
                                      categoryId: catId,
                                      startTime: startDt,
                                      endTime: endDt,
                                    );
                                  } else if (activeTab == CreateItemTab.note) {
                                    await provider.createDateNote(
                                      title: titleController.text.trim(),
                                      date: CalendarProvider.formatDate(eventDate),
                                      content: contentController.text.trim(),
                                    );
                                  } else if (activeTab ==
                                      CreateItemTab.reminder) {
                                    final timeStr =
                                        '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}';

                                    await provider.createReminder(
                                      title: titleController.text.trim(),
                                      date: CalendarProvider.formatDate(eventDate),
                                      time: timeStr,
                                      description: descController.text.trim(),
                                    );
                                  }

                                  if (dialogCtx.mounted) {
                                    Navigator.pop(dialogCtx);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                activeTab == CreateItemTab.event
                                    ? 'Save event'
                                    : activeTab == CreateItemTab.note
                                        ? 'Save note'
                                        : 'Save reminder',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // Dialog: Edit Event
  // ==========================================

  void _showEditEventDialog(CalendarEvent event) {
    final provider = context.read<CalendarProvider>();
    final titleController = TextEditingController(text: event.title);
    final descController = TextEditingController(text: event.description);
    final locController = TextEditingController(text: event.location);

    TimeOfDay startTime = TimeOfDay(
      hour: event.startTime.hour,
      minute: event.startTime.minute,
    );
    TimeOfDay endTime = TimeOfDay(
      hour: event.endTime.hour,
      minute: event.endTime.minute,
    );

    String? selectedCategoryId =
        event.categoryId != null && event.categoryId!.isNotEmpty
            ? event.categoryId
            : null;
    bool isAddingCategory = false;
    final newCatNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isDark ? BorderSide(color: borderColor) : BorderSide.none,
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Event',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(dialogCtx),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Title',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Time',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: startTime,
                                      );
                                      if (picked != null) {
                                        setDialogState(() => startTime = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTime12h(startTime),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 18,
                                            color: Color(0xFF64748B),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'End Time',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: endTime,
                                      );
                                      if (picked != null) {
                                        setDialogState(() => endTime = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTime12h(endTime),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 18,
                                            color: Color(0xFF64748B),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildCategorySelector(
                          provider: provider,
                          selectedCategoryId: selectedCategoryId,
                          isAddingCategory: isAddingCategory,
                          newCatNameController: newCatNameController,
                          onAddingCategoryChanged: (adding) {
                            setDialogState(() => isAddingCategory = adding);
                          },
                          onCategorySelected: (catId) {
                            setDialogState(() => selectedCategoryId = catId);
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descController,
                          maxLines: 4,
                          minLines: 3,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2563EB)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await provider.deleteEvent(event.id);
                                  if (dialogCtx.mounted) {
                                    Navigator.pop(dialogCtx);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete event: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEF2F2),
                                foregroundColor: const Color(0xFFEF4444),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (titleController.text.trim().isEmpty) return;

                                    final startDt = DateTime(
                                      event.startTime.year,
                                      event.startTime.month,
                                      event.startTime.day,
                                      startTime.hour,
                                      startTime.minute,
                                    );
                                    final endDt = DateTime(
                                      event.startTime.year,
                                      event.startTime.month,
                                      event.startTime.day,
                                      endTime.hour,
                                      endTime.minute,
                                    );

                                    try {
                                      String? updateCatId = selectedCategoryId;
                                      if (isAddingCategory &&
                                          newCatNameController.text.trim().isNotEmpty) {
                                        final createdCat =
                                            await provider.createCategory(
                                          name: newCatNameController.text.trim(),
                                          color: '#2563EB',
                                        );
                                        updateCatId = createdCat.id;
                                      }
                                      await provider.updateEvent(
                                        event.id,
                                        title: titleController.text.trim(),
                                        description: descController.text.trim(),
                                        location: locController.text.trim(),
                                        categoryId: updateCatId,
                                        startTime: startDt,
                                        endTime: endDt,
                                      );
                                      if (dialogCtx.mounted) {
                                        Navigator.pop(dialogCtx);
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed: $e')),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Save event',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // Helper: Segmented Tab
  // ==========================================

  Widget _buildSegmentedTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Helper: Category Selector & Inline Creator (Images 1 & 4)
  // ==========================================

  Widget _buildCategorySelector({
    required CalendarProvider provider,
    required String? selectedCategoryId,
    required bool isAddingCategory,
    required TextEditingController newCatNameController,
    required ValueChanged<bool> onAddingCategoryChanged,
    required ValueChanged<String?> onCategorySelected,
  }) {
    // Filter out options like "red"
    final validCats = provider.categories
        .where((c) => c.name.trim().toLowerCase() != 'red')
        .toList();

    final selectedCat = validCats.cast<CalendarCategory?>().firstWhere(
          (c) => c?.id == selectedCategoryId,
          orElse: () => null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.sell_outlined, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 6),
            Text(
              'Category (Optional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Inline Category Creator Mode (Allows manual typing of category name without color picker or options like "red")
        if (isAddingCategory)
          Row(
            children: [
              // Category Name Input
              Expanded(
                child: TextField(
                  controller: newCatNameController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Enter category name...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (val) async {
                    if (val.trim().isEmpty) return;
                    try {
                      final created = await provider.createCategory(
                        name: val.trim(),
                        color: '#2563EB',
                      );
                      onCategorySelected(created.id);
                      onAddingCategoryChanged(false);
                      newCatNameController.clear();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add category: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Add Button
              ElevatedButton(
                onPressed: () async {
                  if (newCatNameController.text.trim().isEmpty) return;
                  try {
                    final created = await provider.createCategory(
                      name: newCatNameController.text.trim(),
                      color: '#2563EB',
                    );
                    onCategorySelected(created.id);
                    onAddingCategoryChanged(false);
                    newCatNameController.clear();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add category: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),

              // Cancel Button (X)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: () {
                  onAddingCategoryChanged(false);
                  newCatNameController.clear();
                },
              ),
            ],
          )
        // Standard Dropdown Mode with "+ Add New Category" (Excludes any options like "red")
        else
          PopupMenuButton<String?>(
            tooltip: 'Select Category',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            elevation: 8,
            onSelected: (val) {
              if (val == '__ADD_NEW__') {
                onAddingCategoryChanged(true);
              } else {
                onCategorySelected(val);
              }
            },
            itemBuilder: (context) {
              return [
                // No Category option
                PopupMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      if (selectedCategoryId == null)
                        const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Color(0xFF0F172A),
                        )
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'No Category',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Existing Categories (excluding "red")
                ...validCats.map((cat) {
                  final isCurrent = cat.id == selectedCategoryId;
                  return PopupMenuItem<String?>(
                    value: cat.id,
                    child: Row(
                      children: [
                        if (isCurrent)
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF0F172A),
                          )
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _parseColor(cat.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          cat.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (validCats.isNotEmpty)
                  const PopupMenuDivider(height: 1),

                // + Add New Category option (Image 1 blue action button)
                PopupMenuItem<String?>(
                  value: '__ADD_NEW__',
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Add New Category',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  if (selectedCat != null) ...[
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _parseColor(selectedCat.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      selectedCat.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'No Category',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // Main Screen Build Methods
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final events = provider.events;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _buildHeader(provider),
          const SizedBox(height: 20),

          // Search Results View (if active)
          if (provider.searchResults != null) ...[
            _buildSearchResultsCard(provider),
            const SizedBox(height: 20),
          ],

          // Error State with Retry
          if (provider.hasError && events.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.errorMessage ?? 'Failed to load calendar events',
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => provider.fetchInitialData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Main Calendar Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildWeekdayHeader(isDark),
                if (provider.isLoading && events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  _buildMonthDaysGrid(events, provider, isDark),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(CalendarProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 1150;

        return isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderTitle(isDark),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _buildHeaderControls(provider, isDark),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeaderTitle(isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: _buildHeaderControls(provider, isDark)),
                      ),
                    ),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildHeaderTitle(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.calendar_today_rounded,
            color: Color(0xFF2563EB),
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Calendar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage your events, notes, and reminders',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHeaderControls(CalendarProvider provider, bool isDark) {
    final controlBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final controlBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textCol = isDark ? Colors.white : const Color(0xFF0F172A);

    return [
      // All Apps Filter Dropdown
      Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: controlBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: controlBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            dropdownColor: controlBg,
            value: _selectedAppFilter,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            items: _appFilters.map((app) {
              return DropdownMenuItem(
                value: app,
                child: Text(
                  app,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedAppFilter = val);
              }
            },
          ),
        ),
      ),
      const SizedBox(width: 8),

      // Search everything... pill
      Container(
        width: 170,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: controlBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: controlBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 18,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search everything...',
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                style: TextStyle(fontSize: 12, color: textCol),
                onChanged: (val) {
                  provider.searchCalendar(val);
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  provider.clearSearch();
                },
                child: Icon(Icons.close, size: 14, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
          ],
        ),
      ),
      const SizedBox(width: 8),

      // Explicit Refresh Button
      Tooltip(
        message: 'Refresh calendar',
        child: InkWell(
          onTap: () => provider.refresh(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: controlBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: controlBorder),
            ),
            child: provider.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
          ),
        ),
      ),
      const SizedBox(width: 8),

      // Month Navigator Pill (< October 2026 >)
      Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: controlBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: controlBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: provider.previousMonth,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${_months[provider.currentMonth.month - 1]} ${provider.currentMonth.year}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ),
            InkWell(
              onTap: provider.nextMonth,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),

      // Today Button Pill
      InkWell(
        onTap: provider.goToToday,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2563EB).withValues(alpha: 0.5)
                  : const Color(0xFFBFDBFE),
            ),
          ),
          child: const Text(
            'Today',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildWeekdayHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: _weekDays.map((day) {
          return Expanded(
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthDaysGrid(
    List<CalendarEvent> allEvents,
    CalendarProvider provider,
    bool isDark,
  ) {
    final year = provider.currentMonth.year;
    final month = provider.currentMonth.month;

    final firstDayWeekday = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalGridCells = ((firstDayWeekday + daysInMonth + 6) ~/ 7) * 7;

    final monthLeaves = HolidayHelper.getLeavesForMonth(year, month);
    final now = DateTime.now();

    return Table(
      border: TableBorder.symmetric(
        inside: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      children: List.generate(totalGridCells ~/ 7, (weekIndex) {
        return TableRow(
          children: List.generate(7, (colIndex) {
            final cellIndex = weekIndex * 7 + colIndex;
            final dayNumber = cellIndex - firstDayWeekday + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return Container(
                height: 110,
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
              );
            }

            final cellDate = DateTime(year, month, dayNumber);
            final isToday = cellDate.year == now.year &&
                cellDate.month == now.month &&
                cellDate.day == now.day;
            final isSelected = cellDate.year == provider.selectedDate.year &&
                cellDate.month == provider.selectedDate.month &&
                cellDate.day == provider.selectedDate.day;

            final dayEvents = allEvents.where((e) {
              if (!e.matchesDay(year, month, dayNumber)) return false;
              return e.matchesApp(_selectedAppFilter);
            }).toList();

            final dayLeaves = monthLeaves
                .where((h) => h.date.day == dayNumber)
                .toList();

            return InkWell(
              onTap: () {
                provider.selectDate(cellDate);
                provider.fetchSelectedDateItems(cellDate);
                _showDateOverviewDialog(cellDate);
              },
              child: Container(
                height: 110,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day Number Header + Add (+) button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isToday)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$dayNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else if (isSelected)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF334155),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        InkWell(
                          onTap: () {
                            provider.selectDate(cellDate);
                            _showCreateItemDialog(initialDate: cellDate);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.add_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Leaves/Holidays (Green chips)
                    ...dayLeaves.map((h) => _buildLeaveChip(h)),

                    // Real Events (Blue chips)
                    ...dayEvents.take(2).map((e) => _buildEventChip(e)),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildLeaveChip(CalendarHoliday holiday) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1FAE5), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌍 ', style: TextStyle(fontSize: 10)),
          Expanded(
            child: Text(
              holiday.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventChip(CalendarEvent e) {
    final startTimeStr =
        '${e.startTime.hour.toString().padLeft(2, '0')}:${e.startTime.minute.toString().padLeft(2, '0')}';
    final isBnx = e.applicationName.toLowerCase().contains('bnx');

    return InkWell(
      onTap: () => _showEditEventDialog(e),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDBEAFE), width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 10,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 3),
            if (isBnx) ...[
              const Icon(
                Icons.flight_takeoff_rounded,
                size: 10,
                color: Color(0xFF2563EB),
              ),
              const SizedBox(width: 2),
              const Text(
                'BNX ',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
            Expanded(
              child: Text(
                '$startTimeStr ${e.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Search Results Overlay / Card
  // ==========================================

  Widget _buildSearchResultsCard(CalendarProvider provider) {
    final res = provider.searchResults!;
    final total = res.events.length + res.reminders.length + res.notes.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Results for "${provider.searchQuery}" ($total found)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E40AF),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  _searchController.clear();
                  provider.clearSearch();
                },
              ),
            ],
          ),
          if (res.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No matching calendar records found.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            )
          else ...[
            if (res.events.isNotEmpty) ...[
              const Text('Events:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ...res.events.map((e) => Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      title: Text(e.title),
                      subtitle: Text(
                          '${e.startTime.day}/${e.startTime.month}/${e.startTime.year} - ${e.categoryName}'),
                      onTap: () => _showEditEventDialog(e),
                    ),
                  )),
            ],
            if (res.reminders.isNotEmpty) ...[
              const Text('Reminders:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ...res.reminders.map((r) => Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      title: Text(r.title),
                      subtitle: Text('${r.date} ${r.time}'),
                    ),
                  )),
            ],
            if (res.notes.isNotEmpty) ...[
              const Text('Date Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ...res.notes.map((n) => Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      title: Text(n.title),
                      subtitle: Text(n.content),
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }
}
