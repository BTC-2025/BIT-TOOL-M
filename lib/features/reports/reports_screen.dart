import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap header elements to dynamically handle narrow mobile screens without overflows
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Text(
                'Performance Reports',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeumorphicButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: () {
                      reportsProvider.simulateExport('PDF');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PDF Summary Exported successfully.'),
                        ),
                      );
                    },
                    child: const Text(
                      'Export PDF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeumorphicButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: () {
                      reportsProvider.simulateExport('CSV');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV Data Exported successfully.'),
                        ),
                      );
                    },
                    child: const Text(
                      'Export CSV',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart 1
          NeumorphicCard(
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Module Usage Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: 8,
                              color: Colors.blue,
                              width: 16,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: 5,
                              color: Colors.green,
                              width: 16,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 2,
                          barRods: [
                            BarChartRodData(
                              toY: 12,
                              color: Colors.red,
                              width: 16,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 3,
                          barRods: [
                            BarChartRodData(
                              toY: 3,
                              color: Colors.amber,
                              width: 16,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 4,
                          barRods: [
                            BarChartRodData(
                              toY: 7,
                              color: Colors.purple,
                              width: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info Card
          const NeumorphicCard(
            borderRadius: 16,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.security, color: Colors.red),
                  title: Text('Security Verification Integrity'),
                  subtitle: Text(
                    'B2Auth verified 100% of user authentication tokens.',
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.sync, color: Colors.blue),
                  title: Text('Sync Synchronizations'),
                  subtitle: Text(
                    'All local actions synchronized to database mock servers.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
