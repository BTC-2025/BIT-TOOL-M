import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/session_provider.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  String _filterModule = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Session Timeline',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV Export Simulated Successfully!')),
                      );
                    },
                    child: const Text('CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF Export Simulated Successfully!')),
                      );
                    },
                    child: const Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekly Activity Ticker
          NeumorphicCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Activity Ticker',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((index) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                strokeWidth: 2,
                                dashArray: [5, 5],
                              ),
                              FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: Theme.of(context).primaryColor,
                                    strokeWidth: 2.5,
                                    strokeColor: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF1B2336)
                              : Colors.white,
                          tooltipBorder: BorderSide(
                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                          tooltipRoundedRadius: 10,
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final flSpot = barSpot;
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              final dayName = days[flSpot.x.toInt() % days.length];
                              return LineTooltipItem(
                                '$dayName\n${flSpot.y.toStringAsFixed(1)} hrs',
                                TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 4),
                            FlSpot(2, 2.5),
                            FlSpot(3, 5),
                            FlSpot(4, 3.8),
                            FlSpot(5, 6),
                            FlSpot(6, 4.2),
                          ],
                          isCurved: true,
                          barWidth: 4,
                          color: Theme.of(context).primaryColor,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Live Activity Ticker
          const Text(
            'Live Activity Ticker',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              final list = sessionProvider.activities
                  .where((act) => act.module != 'Authentication' && act.module != 'BNX Mail')
                  .take(3)
                  .toList();
              if (list.isEmpty) {
                return const Center(child: Text('No logs available.'));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final act = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NeumorphicCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: 12,
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act.description,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${act.module} • ${act.device}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            act.status,
                            style: TextStyle(
                              color: act.status == 'Success' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          NeumorphicTextField(
            hintText: 'Search sessions...',
            prefixIcon: Icons.search,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Calendar', 'Contacts', 'Messages', 'Calculator'].map((module) {
                final isSelected = _filterModule == module;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: NeumorphicButton(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                    onPressed: () {
                      setState(() {
                        _filterModule = module;
                      });
                    },
                    child: Text(
                      module,
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
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              final filtered = sessionProvider.activities.where((act) {
                // Exclude Authentication and BNX Mail from the list entirely
                if (act.module == 'Authentication' || act.module == 'BNX Mail') return false;

                final matchModule = _filterModule == 'All' || act.module == _filterModule;
                final matchQuery = act.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    act.module.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchModule && matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No session logs found.'));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final act = filtered[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: NeumorphicCard(
                      borderRadius: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: NeumorphicDecoration.build(
                              context: context,
                              inset: true,
                              borderRadius: 50,
                            ),
                            child: Icon(_getIcon(act.iconName), color: Theme.of(context).primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        act.module,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${act.timestamp.hour}:${act.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  act.description,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildMetaTag(context, act.device),
                                    _buildMetaTag(context, 'Dur: ${act.duration}'),
                                    _buildStatusBadge(act.status),
                                  ],
                                ),
                              ],
                            ),
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

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'login':
        return Icons.login;
      case 'mail':
        return Icons.mail;
      case 'calculate':
        return Icons.calculate;
      case 'contact_page':
        return Icons.contact_page;
      case 'security':
        return Icons.security;
      case 'event':
        return Icons.event;
      case 'chat':
        return Icons.chat;
      case 'cloud_upload':
        return Icons.cloud_upload;
      default:
        return Icons.info;
    }
  }

  Widget _buildMetaTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isSuccess = status == 'Success' || status == 'Pending';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          color: isSuccess ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
