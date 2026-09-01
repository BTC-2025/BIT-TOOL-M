import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/neumorphic_widgets.dart';
import '../../core/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _activeView = 'Month';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  String _eventCategory = 'Meeting';

  // Calendar State
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  // Quick Event State
  bool _showQuickAdd = false;
  final TextEditingController _quickTitleController = TextEditingController();
  String _quickCategory = 'Meeting';

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Schedule New Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeumorphicTextField(
                      controller: _titleController,
                      hintText: 'Event Title',
                    ),
                    const SizedBox(height: 12),
                    NeumorphicTextField(
                      controller: _descController,
                      hintText: 'Description',
                    ),
                    const SizedBox(height: 12),
                    NeumorphicTextField(
                      controller: _locController,
                      hintText: 'Location (e.g. Teams, Room 101)',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _eventCategory,
                      decoration: const InputDecoration(border: InputBorder.none),
                      items: ['Meeting', 'Birthday', 'Holiday'].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            _eventCategory = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                NeumorphicButton(
                  onPressed: () {
                    final newEvent = CalendarEvent(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleController.text,
                      description: _descController.text,
                      startTime: _selectedDate,
                      endTime: _selectedDate.add(const Duration(hours: 1)),
                      isRecurring: false,
                      colorHex: _getColorForCategory(_eventCategory),
                      category: _eventCategory,
                      location: _locController.text,
                    );
                    context.read<CalendarProvider>().addEvent(newEvent);
                    _titleController.clear();
                    _descController.clear();
                    _locController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getColorForCategory(String category) {
    switch (category) {
      case 'Meeting':
        return 'FF3B82F6'; // Blue
      case 'Birthday':
        return 'FFE91E63'; // Pink
      case 'Holiday':
        return 'FF4CAF50'; // Green
      default:
        return 'FF9C27B0'; // Purple
    }
  }

  Widget _buildMonthlyGrid(BuildContext context, CalendarProvider provider) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final startOffset = firstDayOfMonth.weekday - 1;
    final today = DateTime.now();

    return NeumorphicCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${_getMonthName(_focusedDate.month)} ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  DropdownButton<int>(
                    value: _focusedDate.year,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                    underline: const SizedBox.shrink(),
                    items: List.generate(2035 - 2000 + 1, (index) => 2000 + index).map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (yr) {
                      if (yr != null) {
                        setState(() {
                          _focusedDate = DateTime(yr, _focusedDate.month);
                        });
                      }
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days
                .map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: 42, // Supports all offsets
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              
              if (!isCurrentMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;

              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;

              final dayEvents = provider.events.where((e) =>
                  e.startTime.year == cellDate.year &&
                  e.startTime.month == cellDate.month &&
                  e.startTime.day == cellDate.day).toList();

              final dayHolidays = dayEvents.where((e) => e.category == 'Holiday').toList();
              final isHoliday = dayHolidays.isNotEmpty;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = cellDate;
                    _showQuickAdd = true;
                  });
                  if (isHoliday) {
                    _showHolidayDetailsDialog(context, dayHolidays.first);
                  }
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : (isToday ? Theme.of(context).primaryColor.withOpacity(0.15) : null),
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
                        : (isHoliday 
                            ? Border.all(color: const Color(0xFFFF9800), width: 1.5) 
                            : (isToday ? Border.all(color: Theme.of(context).primaryColor, width: 1) : null)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          fontWeight: (isToday || isSelected || isHoliday) ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isHoliday 
                                  ? const Color(0xFFFF9800) 
                                  : (isToday ? Theme.of(context).primaryColor : null)),
                          fontSize: 13,
                        ),
                      ),
                      if (dayEvents.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayEvents.take(3).map((e) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Color(int.parse(e.colorHex, radix: 16)),
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showHolidayDetailsDialog(BuildContext context, CalendarEvent holiday) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFF9800)),
              const SizedBox(width: 8),
              Expanded(child: Text(holiday.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Government Holiday', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFFF9800))),
              const SizedBox(height: 8),
              Text(holiday.description, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Scope: ${holiday.location}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAddPanel(BuildContext context) {
    if (!_showQuickAdd) return const SizedBox.shrink();

    final dateStr = "${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}";

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: NeumorphicCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Add Event: $dateStr',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _showQuickAdd = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: NeumorphicTextField(
                    controller: _quickTitleController,
                    hintText: 'New Event Title',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: NeumorphicDecoration.build(
                      context: context,
                      inset: true,
                      borderRadius: 14,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _quickCategory,
                        isExpanded: true,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? NeumorphicTheme.darkText
                              : NeumorphicTheme.lightText,
                          fontSize: 14,
                        ),
                        items: ['Meeting', 'Birthday', 'Holiday'].map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _quickCategory = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NeumorphicButton(
              onPressed: () {
                if (_quickTitleController.text.trim().isEmpty) return;
                final newEvent = CalendarEvent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: _quickTitleController.text.trim(),
                  description: 'Created via Quick Add',
                  startTime: _selectedDate,
                  endTime: _selectedDate.add(const Duration(hours: 1)),
                  isRecurring: false,
                  colorHex: _getColorForCategory(_quickCategory),
                  category: _quickCategory,
                  location: 'Workspace',
                );
                context.read<CalendarProvider>().addEvent(newEvent);
                _quickTitleController.clear();
                setState(() {
                  _showQuickAdd = false;
                });
              },
              color: Theme.of(context).primaryColor,
              child: const Text(
                'Save Event',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyView(BuildContext context, CalendarProvider provider) {
    final today = DateTime.now();
    // Find Monday of the current focused week
    final weekday = _focusedDate.weekday;
    final monday = _focusedDate.subtract(Duration(days: weekday - 1));
    
    return NeumorphicCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week of ${monday.day} ${_getMonthName(monday.month)} ${monday.year}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 22),
                    onPressed: () {
                      setState(() {
                        _focusedDate = _focusedDate.subtract(const Duration(days: 7));
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 22),
                    onPressed: () {
                      setState(() {
                        _focusedDate = _focusedDate.add(const Duration(days: 7));
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayDate = monday.add(Duration(days: index));
              const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final isSelected = dayDate.year == _selectedDate.year &&
                  dayDate.month == _selectedDate.month &&
                  dayDate.day == _selectedDate.day;
              final isToday = dayDate.year == today.year &&
                  dayDate.month == today.month &&
                  dayDate.day == today.day;
              
              final dayEvents = provider.events.where((e) =>
                  e.startTime.year == dayDate.year &&
                  e.startTime.month == dayDate.month &&
                  e.startTime.day == dayDate.day).toList();

              final holiday = dayEvents.where((e) => e.category == 'Holiday').firstOrNull;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = dayDate;
                      _showQuickAdd = true;
                    });
                    if (holiday != null) {
                      _showHolidayDetailsDialog(context, holiday);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : (isToday ? Theme.of(context).primaryColor.withOpacity(0.15) : null),
                      borderRadius: BorderRadius.circular(10),
                      border: (holiday != null)
                          ? Border.all(color: const Color(0xFFFF9800), width: 1.5)
                          : (isToday && !isSelected
                              ? Border.all(color: Theme.of(context).primaryColor, width: 1)
                              : null),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weekdays[index],
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayDate.day.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white 
                                : (holiday != null ? const Color(0xFFFF9800) : (isToday ? Theme.of(context).primaryColor : null)),
                          ),
                        ),
                        if (holiday != null)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.star, size: 8, color: Color(0xFFFF9800)),
                          )
                        else if (dayEvents.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyView(BuildContext context, CalendarProvider provider) {
    final dateStr = "${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}";
    final dayEvents = provider.events.where((e) =>
        e.startTime.year == _selectedDate.year &&
        e.startTime.month == _selectedDate.month &&
        e.startTime.day == _selectedDate.day).toList();

    return NeumorphicCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schedule for $dateStr',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                icon: const Icon(Icons.today, size: 20),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                    _focusedDate = DateTime.now();
                  });
                },
              ),
            ],
          ),
          const Divider(),
          if (dayEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No events scheduled for this day.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayEvents.length,
              itemBuilder: (context, idx) {
                final e = dayEvents[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${e.startTime.hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(int.parse(e.colorHex, radix: 16)).withOpacity(0.08),
                            border: Border(
                              left: BorderSide(
                                color: Color(int.parse(e.colorHex, radix: 16)),
                                width: 4,
                              ),
                            ),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (e.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  e.description,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = Provider.of<CalendarProvider>(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Interactive Calendar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              NeumorphicButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: _showAddEventDialog,
                color: Theme.of(context).primaryColor,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Month', 'Week', 'Day'].map((view) {
                final isSelected = _activeView == view;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                    onPressed: () {
                      setState(() {
                        _activeView = view;
                      });
                    },
                    child: Text(
                      view,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Switch between active calendar views
          if (_activeView == 'Month') _buildMonthlyGrid(context, calendarProvider),
          if (_activeView == 'Week') _buildWeeklyView(context, calendarProvider),
          if (_activeView == 'Day') _buildDailyView(context, calendarProvider),
          
          _buildQuickAddPanel(context),
          const SizedBox(height: 24),
          const Text(
            'Upcoming Events',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final nonHolidays = calendarProvider.events.where((e) => e.category != 'Holiday').toList();
              if (nonHolidays.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No events scheduled.'),
                ));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nonHolidays.length,
                itemBuilder: (context, i) {
                  final event = nonHolidays[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NeumorphicCard(
                      borderRadius: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 5,
                            height: 65,
                            decoration: BoxDecoration(
                              color: Color(int.parse(event.colorHex, radix: 16)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.description,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(
                                          event.location.isEmpty ? 'Workspace' : event.location,
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time, size: 12, color: Colors.grey),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${event.startTime.day} ${_getMonthName(event.startTime.month)} - ${event.startTime.hour}:00',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => calendarProvider.deleteEvent(event.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
