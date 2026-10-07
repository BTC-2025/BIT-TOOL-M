import 'package:flutter/material.dart';
import '../../core/widgets/neumorphic_widgets.dart';
import '../../core/theme/app_spacing.dart';

class SearchScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const SearchScreen({super.key, required this.onNavigate});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _modules = [
    {'title': 'Home', 'index': 0, 'icon': Icons.grid_view_rounded},
    {'title': 'Activities', 'index': 1, 'icon': Icons.bar_chart_rounded},
    {'title': 'Mail', 'index': 2, 'icon': Icons.email_outlined},
    {'title': 'Calendar', 'index': 3, 'icon': Icons.calendar_today_rounded},
    {'title': 'Calculator', 'index': 4, 'icon': Icons.calculate_outlined},
    {'title': 'Contacts', 'index': 5, 'icon': Icons.people_outline_rounded},
    {'title': 'Messages', 'index': 6, 'icon': Icons.forum_outlined},
    {'title': 'Authentication', 'index': 7, 'icon': Icons.security_rounded},
    {'title': 'Devices', 'index': 8, 'icon': Icons.important_devices_rounded},
    {'title': 'Files', 'index': 9, 'icon': Icons.folder_open_rounded},
    {'title': 'Reports', 'index': 10, 'icon': Icons.analytics_rounded},
    {'title': 'Profile', 'index': 11, 'icon': Icons.person_outline_rounded},
    {'title': 'News', 'index': 12, 'icon': Icons.newspaper_rounded},
    {'title': 'Keyboard', 'index': 13, 'icon': Icons.keyboard_outlined},
    {'title': 'Translator', 'index': 14, 'icon': Icons.translate_rounded},
    {'title': 'Lens', 'index': 15, 'icon': Icons.camera_alt_outlined},
    {'title': 'Weather', 'index': 16, 'icon': Icons.cloud_outlined},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        NeumorphicCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          child: NeumorphicTextField(
            controller: _searchController,
            hintText: 'Search modules (e.g. Lens, Calc, Mail)...',
            prefixIcon: Icons.search,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: NeumorphicCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(16),
            child: _searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.manage_search_rounded,
                          size: 64,
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Search for any module to navigate instantly',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final filteredModules = _modules
                          .where(
                            (m) => m['title'].toString().toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                      if (filteredModules.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matching modules found.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredModules.length,
                        itemBuilder: (context, i) {
                          final mod = filteredModules[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NeumorphicButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              borderRadius: 16,
                              onPressed: () => widget.onNavigate(mod['index']),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      mod['icon'],
                                      color: Theme.of(context).primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mod['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Navigate to ${mod['title']} module',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
