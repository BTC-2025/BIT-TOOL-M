import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import 'user_avatar.dart';
import '../../features/calculator/calculator_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/contacts/contacts_screen.dart';
import '../../features/weather/weather_screen.dart';
import '../../features/keyboard/keyboard_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/sign_in_screen.dart';

class _SearchResultItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color iconColor;
  final List<String> keywords;
  final VoidCallback onTap;

  _SearchResultItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.iconColor,
    this.keywords = const [],
    required this.onTap,
  });
}

class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _currentIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;

  final List<String> _titles = [
    'Calculator',
    'Calendar',
    'Notes',
    'Contacts',
    'Weather',
    'Keyboard',
  ];

  final List<IconData> _icons = [
    Icons.calculate_outlined,
    Icons.calendar_today_outlined,
    Icons.description_outlined,
    Icons.people_outline_rounded,
    Icons.cloud_outlined,
    Icons.keyboard_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _hideSearchOverlay();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _showSearchOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _hideSearchOverlay();
        }
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _switchTab(int index) {
    _hideSearchOverlay();
    _searchFocusNode.unfocus();
    setState(() => _currentIndex = index);
  }

  void _showSearchOverlay() {
    if (!mounted) return;
    if (_searchOverlayEntry != null) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _searchOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        final isDark = Theme.of(overlayContext).brightness == Brightness.dark;
        return Positioned(
          width: 380,
          child: CompositedTransformFollower(
            link: _searchLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 44),
            child: TapRegion(
              groupId: 'header_search',
              child: Material(
                elevation: 10,
                shadowColor: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(16),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 380),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (ctx, value, _) {
                      final results = _getFilteredResults(value.text);
                      return _buildSearchResultsList(
                        results,
                        isDark,
                        value.text,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_searchOverlayEntry!);
  }

  void _hideSearchOverlay() {
    if (_searchOverlayEntry != null) {
      if (_searchOverlayEntry!.mounted) {
        _searchOverlayEntry!.remove();
      }
      _searchOverlayEntry = null;
    }
  }

  String _formatEventDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
  }

  List<_SearchResultItem> _getFilteredResults(String query) {
    final q = query.trim().toLowerCase();
    final List<_SearchResultItem> results = [];

    // 1. Core Tools
    final allTools = [
      _SearchResultItem(
        title: 'Calculator',
        subtitle: 'Math calculations, GST tax, discount & tape history',
        category: 'Tools',
        icon: Icons.calculate_outlined,
        iconColor: const Color(0xFF3B82F6),
        keywords: [
          'calc',
          'calculator',
          'math',
          'gst',
          'tax',
          'discount',
          'tape',
          'history',
          'sum',
          'add',
          'bnx',
          'bnx mail',
          'cliks',
          'cliks business',
          'cross-app',
          'cross app',
        ],
        onTap: () => _switchTab(0),
      ),
      _SearchResultItem(
        title: 'Calendar',
        subtitle: 'Schedule meetings, agendas & events',
        category: 'Tools',
        icon: Icons.calendar_today_outlined,
        iconColor: const Color(0xFF8B5CF6),
        keywords: [
          'calendar',
          'cal',
          'schedule',
          'event',
          'events',
          'meeting',
          'date',
          'agenda',
        ],
        onTap: () => _switchTab(1),
      ),
      _SearchResultItem(
        title: 'Notes',
        subtitle: 'Personal notes, scratchpad & markdown docs',
        category: 'Tools',
        icon: Icons.description_outlined,
        iconColor: const Color(0xFFF59E0B),
        keywords: [
          'notes',
          'note',
          'scratchpad',
          'memo',
          'text',
          'doc',
          'write',
          'todo',
        ],
        onTap: () => _switchTab(2),
      ),
      _SearchResultItem(
        title: 'Contacts',
        subtitle: 'Directory, teammates & client address book',
        category: 'Tools',
        icon: Icons.people_outline_rounded,
        iconColor: const Color(0xFF10B981),
        keywords: [
          'contacts',
          'contact',
          'people',
          'team',
          'phonebook',
          'colleagues',
          'directory',
        ],
        onTap: () => _switchTab(3),
      ),
      _SearchResultItem(
        title: 'Weather',
        subtitle: 'Live forecast, temperatures & conditions',
        category: 'Tools',
        icon: Icons.cloud_outlined,
        iconColor: const Color(0xFF06B6D4),
        keywords: [
          'weather',
          'forecast',
          'temperature',
          'climate',
          'sun',
          'rain',
          'humidity',
        ],
        onTap: () => _switchTab(4),
      ),
      _SearchResultItem(
        title: 'Keyboard',
        subtitle: 'Virtual keypad, typing tests & emoji pad',
        category: 'Tools',
        icon: Icons.keyboard_outlined,
        iconColor: const Color(0xFFEC4899),
        keywords: [
          'keyboard',
          'keypad',
          'typing',
          'keys',
          'emoji',
          'typewriter',
          'symbols',
        ],
        onTap: () => _switchTab(5),
      ),
      _SearchResultItem(
        title: 'Settings',
        subtitle: 'Theme preferences, dark mode & app options',
        category: 'Tools',
        icon: Icons.settings_outlined,
        iconColor: const Color(0xFF64748B),
        keywords: [
          'settings',
          'preferences',
          'dark mode',
          'light mode',
          'theme',
          'config',
        ],
        onTap: () => _switchTab(6),
      ),
    ];

    if (q.isEmpty) {
      return allTools;
    }

    for (final tool in allTools) {
      if (tool.title.toLowerCase().contains(q) ||
          tool.subtitle.toLowerCase().contains(q) ||
          tool.keywords.any((k) => k.contains(q))) {
        results.add(tool);
      }
    }

    // 2. Contacts
    try {
      final contacts = context.read<ContactsProvider>().contacts;
      for (final c in contacts) {
        if (c.name.toLowerCase().contains(q) ||
            c.company.toLowerCase().contains(q) ||
            c.designation.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.department.toLowerCase().contains(q)) {
          final subtitleParts = [
            if (c.designation.isNotEmpty) c.designation,
            if (c.company.isNotEmpty) c.company,
            if (c.email.isNotEmpty) c.email,
          ];
          results.add(
            _SearchResultItem(
              title: c.name,
              subtitle: subtitleParts.join(' • '),
              category: 'Contacts',
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF10B981),
              onTap: () {
                _switchTab(3);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected contact: ${c.name}'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          );
        }
      }
    } catch (_) {}

    // 3. Notes
    try {
      final notes = context.read<NotesProvider>().notes;
      for (final n in notes) {
        if (n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q) ||
            n.category.toLowerCase().contains(q)) {
          final cleanContent = n.content.replaceAll('\n', ' ').trim();
          final snippet = cleanContent.length > 45
              ? '${cleanContent.substring(0, 45)}...'
              : cleanContent;
          results.add(
            _SearchResultItem(
              title: n.title.isNotEmpty ? n.title : 'Untitled Note',
              subtitle: '${n.category} • $snippet',
              category: 'Notes',
              icon: Icons.description_rounded,
              iconColor: const Color(0xFFF59E0B),
              onTap: () {
                _switchTab(2);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected note: ${n.title}'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          );
        }
      }
    } catch (_) {}

    // 4. Calendar Events
    try {
      final events = context.read<CalendarProvider>().events;
      for (final e in events) {
        if (e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q)) {
          results.add(
            _SearchResultItem(
              title: e.title,
              subtitle: '${e.category} • ${_formatEventDate(e.startTime)}',
              category: 'Calendar',
              icon: Icons.event_rounded,
              iconColor: const Color(0xFF8B5CF6),
              onTap: () {
                _switchTab(1);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected event: ${e.title}'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          );
        }
      }
    } catch (_) {}

    return results;
  }

  Widget _buildSearchResultsList(
    List<_SearchResultItem> results,
    bool isDark,
    String query, {
    VoidCallback? onItemTapped,
  }) {
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 36,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              'No matches found for "$query"',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF334155),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching for tools, contacts, notes, or calendar events.',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final Map<String, List<_SearchResultItem>> grouped = {};
    for (final item in results) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in grouped.entries) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            for (final item in entry.value)
              InkWell(
                onTap: () {
                  onItemTapped?.call();
                  item.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: item.iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, size: 18, color: item.iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showMobileSearchDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = _searchController.text;
            final results = _getFilteredResults(query);

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: (_) => setModalState(() {}),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search tools, contacts, notes...',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setModalState(() {});
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildSearchResultsList(
                      results,
                      isDark,
                      _searchController.text,
                      onItemTapped: () => Navigator.pop(modalContext),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const CalculatorScreen();
      case 1:
        return const CalendarScreen();
      case 2:
        return const NotesScreen();
      case 3:
        return const ContactsScreen();
      case 4:
        return const WeatherScreen();
      case 5:
        return const KeyboardScreen();
      case 6:
        return const SettingsScreen();
      default:
        return const CalculatorScreen();
    }
  }

  NotificationProvider? _getNotificationProvider({bool listen = true}) {
    try {
      return Provider.of<NotificationProvider>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }

  IconData _getNotificationIcon(String? type) {
    if (type == null) return Icons.notifications_rounded;
    switch (type.toLowerCase()) {
      case 'calendar':
      case 'event':
      case 'meeting':
        return Icons.event_rounded;
      case 'weather':
        return Icons.cloud_sync_rounded;
      case 'contact':
      case 'contacts':
        return Icons.contacts_rounded;
      case 'note':
      case 'notes':
        return Icons.note_alt_rounded;
      case 'account':
      case 'auth':
      case 'security':
        return Icons.security_rounded;
      case 'system':
      case 'alert':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String? type, bool isDark) {
    if (type == null) return const Color(0xFF3B82F6);
    switch (type.toLowerCase()) {
      case 'calendar':
      case 'event':
      case 'meeting':
        return const Color(0xFF10B981);
      case 'weather':
        return const Color(0xFF3B82F6);
      case 'contact':
      case 'contacts':
        return const Color(0xFF8B5CF6);
      case 'security':
      case 'alert':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  void _showNotificationsPanel() {
    debugPrint(
      '[NotificationUI] Bell clicked, opening notification dropdown panel.',
    );
    final notifProvider = _getNotificationProvider(listen: false);
    if (notifProvider != null) {
      notifProvider.fetchNotifications();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 768;

    if (isDesktop) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Notifications',
        barrierColor: Colors.black.withValues(alpha: 0.25),
        pageBuilder: (dialogContext, anim1, anim2) {
          return SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 380,
                  constraints: const BoxConstraints(maxHeight: 520),
                  margin: const EdgeInsets.only(top: 64, right: 64),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isDark
                        ? Border.all(color: const Color(0xFF334155))
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.1,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildNotificationsContent(dialogContext, isDark),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: _buildNotificationsContent(sheetContext, isDark),
          );
        },
      );
    }
  }

  Widget _buildNotificationsContent(BuildContext panelContext, bool isDark) {
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        final notifications = notifProvider.notifications;
        final unreadCount = notifProvider.unreadCount;
        final isLoading = notifProvider.isLoading;
        final hasError = notifProvider.hasError;
        final isEmpty = notifProvider.isEmpty;
        final isMarkingAll = notifProvider.isMarkingAllAsRead;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Notifications',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount new',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      TextButton(
                        onPressed: isMarkingAll
                            ? null
                            : () => notifProvider.markAllAsRead(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: isMarkingAll
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : const Text('Mark All Read'),
                      )
                    else
                      TextButton(
                        onPressed: null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Mark All Read',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),

              // Content states
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading notifications...',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 24,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 28,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          notifProvider.errorMessage ??
                              'Failed to load notifications.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (notifProvider.errorMessage
                                    ?.toLowerCase()
                                    .contains('sign in') ==
                                true)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(panelContext).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SignInScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.login_rounded, size: 16),
                                label: const Text('Sign In'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: () => notifProvider.fetchNotifications(
                                forceRefresh: true,
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    notifProvider.errorMessage
                                            ?.toLowerCase()
                                            .contains('sign in') ==
                                        true
                                    ? (isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0))
                                    : const Color(0xFF2563EB),
                                foregroundColor:
                                    notifProvider.errorMessage
                                            ?.toLowerCase()
                                            .contains('sign in') ==
                                        true
                                    ? (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A))
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.5)
                                : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 32,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All caught up!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No new notifications',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.5)
                          : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _buildNotificationTile(
                        item,
                        notifProvider,
                        isDark,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(
    NotificationModel item,
    NotificationProvider provider,
    bool isDark,
  ) {
    final isUnread = !item.isRead;
    final isMarking = provider.isItemMarkingRead(item.id);
    final iconData = _getNotificationIcon(item.type);
    final iconColor = _getNotificationColor(item.type, isDark);

    return InkWell(
      onTap: () {
        if (isUnread && !isMarking) {
          provider.markAsRead(item.id);
        }
      },
      child: Container(
        color: isUnread
            ? (isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.15)
                  : const Color(0xFFF8FAFC))
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.isNotEmpty ? item.title : 'Notification',
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (item.message.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.timeAgo.isNotEmpty)
                  Text(
                    item.timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                if (isUnread) ...[
                  const SizedBox(height: 6),
                  if (isMarking)
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF3B82F6),
                      ),
                    )
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  AuthProvider? _getAuthProvider({bool listen = true}) {
    try {
      return Provider.of<AuthProvider>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }

  void _showProfileMenu() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profile',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      pageBuilder: (dialogContext, anim1, anim2) {
        final auth = _getAuthProvider(listen: false);
        final user = auth?.user;
        final isLoading = auth?.isLoading ?? false;
        final hasError = auth?.hasError ?? false;

        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 320,
              margin: const EdgeInsets.only(top: 64, right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.35 : 0.1,
                    ),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: isDark
                        ? Border.all(color: const Color(0xFF334155))
                        : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),
                    if (isLoading) ...[
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading profile...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please wait',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ] else if (user != null) ...[
                      UserAvatar(user: user, radius: 36, fontSize: 22),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          user.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else if (hasError) ...[
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          auth?.errorMessage ?? 'Connection Error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          auth?.retry();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ] else ...[
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        child: Icon(
                          Icons.person_outline,
                          size: 36,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Not Signed In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (user != null) ...[
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          setState(() => _currentIndex = 6);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Manage your Account',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignInScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D6EE5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Sign in to B2Auth',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      height: 1,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.person_add_outlined,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF334155),
                        size: 20,
                      ),
                      title: Text(
                        'Add another account',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF334155),
                        ),
                      ),
                      dense: true,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignInScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.logout_rounded,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF334155),
                        size: 20,
                      ),
                      title: Text(
                        'Sign out of all accounts',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF334155),
                        ),
                      ),
                      dense: true,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        auth?.signOut();
                      },
                    ),
                    Divider(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      height: 1,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Privacy Policy  •  Terms of Service',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E131F)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Navigation Bar ──────────────────────────────────────────
            _buildTopNavBar(isWide, isDark),

            // ─── Main Body Area (Sidebar + Content) ──────────────────────────
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        // Left Sidebar
                        _buildSidebar(isDark),

                        // Screen Content View
                        Expanded(
                          child: Container(
                            color: isDark
                                ? const Color(0xFF0E131F)
                                : const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.all(20),
                            child: _buildScreen(_currentIndex),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildScreen(_currentIndex),
                          ),
                        ),
                        _buildBottomNav(isDark),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar(bool isWide, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo & App Name
          Row(
            children: [
              Image.asset(
                'assets/bit_tool_logo.png',
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.token_rounded,
                  color: Color(0xFF2563EB),
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Bit-tool',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          if (isWide) const SizedBox(width: 36),

          // Search Tools / Contacts Bar
          if (isWide)
            TapRegion(
              groupId: 'header_search',
              onTapOutside: (_) {
                _hideSearchOverlay();
                _searchFocusNode.unfocus();
              },
              child: CompositedTransformTarget(
                link: _searchLayerLink,
                child: Container(
                  width: 320,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus
                          ? const Color(0xFF3B82F6)
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                      width: _searchFocusNode.hasFocus ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: _searchFocusNode.hasFocus
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          key: const ValueKey('HeaderSearchField'),
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onTap: () {
                            if (_searchOverlayEntry == null) {
                              _showSearchOverlay();
                            }
                          },
                          onChanged: (text) {
                            if (_searchOverlayEntry == null &&
                                _searchFocusNode.hasFocus) {
                              _showSearchOverlay();
                            }
                          },
                          onSubmitted: (query) {
                            final results = _getFilteredResults(query);
                            if (results.isNotEmpty) {
                              results.first.onTap();
                            }
                          },
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search tools, contacts...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return GestureDetector(
                            onTap: () {
                              _searchController.clear();
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Spacer(),

          // Mobile Search Button
          if (!isWide)
            IconButton(
              onPressed: _showMobileSearchDialog,
              icon: Icon(
                Icons.search_rounded,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
                size: 22,
              ),
              tooltip: 'Search tools, contacts...',
            ),

          // Notification Bell
          Builder(
            builder: (context) {
              final notifProvider = _getNotificationProvider(listen: true);
              final unreadCount = notifProvider?.unreadCount ?? 0;
              return IconButton(
                onPressed: _showNotificationsPanel,
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    size: 22,
                  ),
                ),
                tooltip: 'Notifications',
              );
            },
          ),

          const SizedBox(width: 8),

          // User Profile Pill
          Builder(
            builder: (context) {
              final authProvider = _getAuthProvider(listen: true);
              final user = authProvider?.user;
              final isLoading = authProvider?.isLoading ?? false;

              return InkWell(
                onTap: () {
                  if (user == null && !isLoading) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  } else {
                    _showProfileMenu();
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading) ...[
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ] else ...[
                        UserAvatar(user: user, radius: 14, fontSize: 11),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            user?.displayName ??
                                (authProvider?.hasError == true
                                    ? 'Error'
                                    : 'Sign in'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
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

  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2B) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Main Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: _titles.length,
              itemBuilder: (context, i) {
                final isSelected = _currentIndex == i;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  child: InkWell(
                    onTap: () => _switchTab(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? const Color(
                                      0xFF2563EB,
                                    ).withValues(alpha: 0.22)
                                  : const Color(0xFFEFF6FF))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF3B82F6),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _icons[i],
                            color: isSelected
                                ? (isDark
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFF2563EB))
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _titles[i],
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                                color: isSelected
                                    ? (isDark
                                          ? const Color(0xFF60A5FA)
                                          : const Color(0xFF2563EB))
                                    : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Secondary Actions
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 6),

          _buildSidebarSecondaryItem(
            isDark: isDark,
            icon: Icons.settings_outlined,
            title: 'Settings',
            isSelected: _currentIndex == 6,
            onTap: () {
              _switchTab(6);
            },
          ),
          _buildSidebarSecondaryItem(
            isDark: isDark,
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support opened'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarSecondaryItem({
    required bool isDark,
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? const Color(0xFF2563EB).withValues(alpha: 0.22)
                      : const Color(0xFFEFF6FF))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB))
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF2563EB))
                        : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_titles.length, (i) {
              final isSelected = _currentIndex == i;
              return Expanded(
                child: InkWell(
                  onTap: () => _switchTab(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _icons[i],
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF2563EB))
                            : (isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF64748B)),
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _titles[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? (isDark
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF2563EB))
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
