import 'package:flutter/material.dart';
import '../../core/widgets/neumorphic_widgets.dart';
import '../../core/theme/app_spacing.dart';

class ModuleItem {
  final String title;
  final IconData icon;
  final int index;
  final String description;
  final List<Color> gradientColors;
  final String category;

  const ModuleItem({
    required this.title,
    required this.icon,
    required this.index,
    required this.description,
    required this.gradientColors,
    required this.category,
  });
}

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PageController _pageController;
  int _activePage = 0;

  final List<ModuleItem> _modules = const [
    ModuleItem(
      title: 'Calculator',
      icon: Icons.calculate_outlined,
      index: 4,
      description:
          'Perform advanced mathematical operations and calculations instantly.',
      gradientColors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      category: 'UTILITY',
    ),
    ModuleItem(
      title: 'Calendar',
      icon: Icons.calendar_today_rounded,
      index: 3,
      description:
          'Organize your schedule, track meetings, and plan your workdays.',
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
      category: 'PRODUCTIVITY',
    ),
    ModuleItem(
      title: 'Contacts',
      icon: Icons.people_outline_rounded,
      index: 5,
      description:
          'Access directory records, manage clients, and coordinate teams.',
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      category: 'ORGANIZATION',
    ),
    ModuleItem(
      title: 'Translator',
      icon: Icons.translate_rounded,
      index: 14,
      description:
          'Instantly translate text and phrases across dynamic global languages.',
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      category: 'COMMUNICATION',
    ),
    ModuleItem(
      title: 'Lens',
      icon: Icons.camera_alt_outlined,
      index: 15,
      description:
          'Analyze objects, scan text, and capture details using your camera.',
      gradientColors: [Color(0xFFEC4899), Color(0xFFDB2777)],
      category: 'VISION AI',
    ),
    ModuleItem(
      title: 'Weather',
      icon: Icons.cloud_outlined,
      index: 16,
      description:
          'Stay updated with live meteorological conditions and local forecasts.',
      gradientColors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      category: 'METRIC',
    ),
    ModuleItem(
      title: 'News Feed',
      icon: Icons.newspaper_rounded,
      index: 12,
      description:
          'Browse global headlines, technology news, and personalized feeds.',
      gradientColors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
      category: 'INFORMATION',
    ),
    ModuleItem(
      title: 'Keyboard',
      icon: Icons.keyboard_outlined,
      index: 13,
      description:
          'Configure layout mapping and speed diagnostics for your inputs.',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      category: 'SYSTEM',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _nextPage() {
    if (_activePage < _modules.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Loop to beginning
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_activePage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Loop to end
      _pageController.animateToPage(
        _modules.length - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, Ravi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back to your premium workspace.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Resource Snapshot Grid
          Text(
            'Resource Snapshot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: width > 1100 ? 5 : (width > 600 ? 3 : 2),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.0,
            children: [
              _buildKpiCard(
                context,
                'Today Sessions',
                '24',
                Icons.history_toggle_off,
                Colors.indigoAccent,
              ),
              _buildKpiCard(
                context,
                'Active Devices',
                '2',
                Icons.devices,
                Colors.green,
              ),
              _buildKpiCard(
                context,
                'Mail Sent Today',
                '12',
                Icons.send_rounded,
                Colors.orangeAccent,
              ),
              _buildKpiCard(
                context,
                'Pending Alerts',
                '1',
                Icons.warning_amber_rounded,
                Colors.redAccent,
              ),
              _buildKpiCard(
                context,
                'Total Contacts',
                '42',
                Icons.people_outline_rounded,
                Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Modules Slider Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workspaces & Modules',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark
                          ? Colors.grey.shade300
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Touch a module to open it',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              // Left & Right Carousel controls
              Row(
                children: [
                  NeumorphicButton(
                    padding: const EdgeInsets.all(10),
                    borderRadius: 50,
                    onPressed: _prevPage,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeumorphicButton(
                    padding: const EdgeInsets.all(10),
                    borderRadius: 50,
                    onPressed: _nextPage,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Interactive Premium Carousel
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _modules.length,
              onPageChanged: (int index) {
                setState(() {
                  _activePage = index;
                });
              },
              itemBuilder: (context, index) {
                final item = _modules[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: NeumorphicButton(
                    padding: EdgeInsets.zero,
                    borderRadius: 24,
                    onPressed: () {
                      if (item.index != -1) {
                        widget.onNavigate(item.index);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.title} module is coming soon!',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Elegant backdrop gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    item.gradientColors[0].withValues(
                                      alpha: isDark ? 0.15 : 0.08,
                                    ),
                                    item.gradientColors[1].withValues(
                                      alpha: isDark ? 0.04 : 0.02,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Soft glowing orb in the top right
                          Positioned(
                            top: -20,
                            right: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: item.gradientColors[0].withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(22.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Category chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.gradientColors[0]
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: item.gradientColors[0],
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    // Neumorphic icon holder
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey.shade900
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: item.gradientColors[0]
                                                .withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        item.icon,
                                        color: item.gradientColors[0],
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : const Color(0xFF475569),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: List.generate(
                                        _modules.length,
                                        (dotIndex) => AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          width: dotIndex == index ? 16 : 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: dotIndex == index
                                                ? item.gradientColors[0]
                                                : (isDark
                                                      ? Colors.grey.shade800
                                                      : Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Launch',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: item.gradientColors[0],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 14,
                                          color: item.gradientColors[0],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String val,
    IconData icon,
    Color color,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return NeumorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
