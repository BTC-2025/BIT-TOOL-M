import 'package:flutter/material.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/sessions/sessions_screen.dart';
import '../../features/mail/mail_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/calculator/calculator_screen.dart';
import '../../features/contacts/contacts_screen.dart';
import '../../features/messages/messages_screen.dart';
import '../../features/authentication/auth_screen.dart';
import '../../features/devices/devices_screen.dart';
import '../../features/files/files_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/news/news_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/translator/translator_screen.dart';
import '../../features/lens/lens_screen.dart';
import '../../features/weather/weather_screen.dart';
import '../../features/keyboard/keyboard_screen.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import 'neumorphic_widgets.dart';

class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _currentIndex = 0;
  bool _isDark = false;

  final List<String> _titles = [
    'Home',
    'Activities',
    'Mail',
    'Calendar',
    'Calculator',
    'Contacts',
    'Messages',
    'Authentication',
    'Devices',
    'Files',
    'Reports',
    'Profile',
    'News',
    'Keyboard',
    'Translator',
    'Lens',
    'Weather',
    'Search',
  ];

  final List<IconData> _icons = [
    Icons.grid_view_rounded,
    Icons.bar_chart_rounded,
    Icons.email_outlined,
    Icons.calendar_today_rounded,
    Icons.calculate_outlined,
    Icons.people_outline_rounded,
    Icons.forum_outlined,
    Icons.security_rounded,
    Icons.important_devices_rounded,
    Icons.folder_open_rounded,
    Icons.analytics_rounded,
    Icons.person_outline_rounded,
    Icons.newspaper_rounded,
    Icons.keyboard_outlined,
    Icons.translate_rounded,
    Icons.camera_alt_outlined,
    Icons.cloud_outlined,
    Icons.search,
  ];

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(
          onNavigate: (newIndex) {
            setState(() {
              _currentIndex = newIndex;
            });
          },
        );
      case 1:
        return const SessionsScreen();
      case 2:
        return const MailScreen();
      case 3:
        return const CalendarScreen();
      case 4:
        return const CalculatorScreen();
      case 5:
        return const ContactsScreen();
      case 6:
        return const MessagesScreen();
      case 7:
        return const AuthScreen();
      case 8:
        return const DevicesScreen();
      case 9:
        return const FilesScreen();
      case 10:
        return const ReportsScreen();
      case 11:
        return SettingsScreen(
          isDark: _isDark,
          onThemeChanged: (val) {
            setState(() {
              _isDark = val;
            });
          },
          onNavigate: (newIndex) {
            setState(() {
              _currentIndex = newIndex;
            });
          },
        );
      case 12:
        return const NewsScreen();
      case 13:
        return const KeyboardScreen();
      case 14:
        return const TranslatorScreen();
      case 15:
        return const LensScreen();
      case 16:
        return const WeatherScreen();
      case 17:
        return SearchScreen(
          onNavigate: (newIndex) {
            setState(() {
              _currentIndex = newIndex;
            });
          },
        );
      default:
        return DashboardScreen(
          onNavigate: (newIndex) {
            setState(() {
              _currentIndex = newIndex;
            });
          },
        );
    }
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NeumorphicCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications Center',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Mark All Read'),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.red),
                title: const Text('Suspicious login blocked'),
                subtitle: const Text(
                  'B2Auth flagged a high-risk access attempt.',
                ),
                trailing: Text(
                  'Just now',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mail, color: Colors.blue),
                title: const Text('New client registration draft'),
                subtitle: const Text('HR team uploaded new evaluation sheets.'),
                trailing: Text(
                  '10m ago',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;
    final primaryColor = Theme.of(context).primaryColor;
    final unselectedColor = Colors.grey.shade500;

    return Theme(
      data: _isDark ? NeumorphicTheme.darkTheme : NeumorphicTheme.lightTheme,
      child: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                _currentIndex == 0
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.multiply,
                        ),
                        child: Image.asset(
                          'assets/images/bit_tool_logo.png',
                          height: 38,
                          width: 38,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.token_rounded,
                              color: primaryColor,
                              size: 28,
                            );
                          },
                        ),
                      )
                    : GestureDetector(
                        onTap: () => setState(() => _currentIndex = 0),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _titles[_currentIndex],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              NeumorphicButton(
                padding: const EdgeInsets.all(8),
                borderRadius: 50,
                onPressed: () {
                  setState(() {
                    _currentIndex = 17; // Navigate to Search Screen
                  });
                },
                child: const Icon(Icons.search, size: 20),
              ),
              const SizedBox(width: 10),
              NeumorphicButton(
                padding: const EdgeInsets.all(8),
                borderRadius: 50,
                onPressed: _showNotificationsPanel,
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Stack(
            children: [
              // ─── Main content ───────────────────────────────────────────────
              isWide
                  ? Row(
                      children: [
                        // Sidebar navigation rail
                        Container(
                          width: 250,
                          color: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 12,
                          ),
                          child: NeumorphicCard(
                            borderRadius: 20,
                            padding: const EdgeInsets.all(8),
                            child: ListView.builder(
                              itemCount: _titles.length,
                              itemBuilder: (context, i) {
                                final isSelected = _currentIndex == i;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: NeumorphicButton(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    borderRadius: 12,
                                    color: isSelected
                                        ? primaryColor.withValues(alpha: 0.1)
                                        : null,
                                    onPressed: () {
                                      setState(() {
                                        _currentIndex = i;
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Icon(
                                          _icons[i],
                                          color: isSelected
                                              ? primaryColor
                                              : unselectedColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _titles[i],
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? primaryColor
                                                  : unselectedColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: AppSpacing.screenPadding,
                            child: _buildScreen(_currentIndex),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: AppSpacing.screenHorizontal,
                            child: _buildScreen(_currentIndex),
                          ),
                        ),
                        // B2Auth Premium Bottom Navigation bar
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: NeumorphicCard(
                              borderRadius: 24,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                height: 55,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildBottomNavItem(
                                      0,
                                      'Home',
                                      Icons.grid_view_rounded,
                                    ),
                                    _buildBottomNavItem(
                                      1,
                                      'Activities',
                                      Icons.bar_chart_rounded,
                                    ),
                                    _buildBottomNavItem(
                                      11,
                                      'Profile',
                                      Icons.person_outline_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

              // ─── Floating Back Button removed ────
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, String label, IconData icon) {
    final bool isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).primaryColor;
    final unselectedColor = Colors.grey.shade500;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : unselectedColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
