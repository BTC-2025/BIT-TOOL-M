import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/session_provider.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class MailScreen extends StatelessWidget {
  const MailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BNX Mail Integration Hub',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Synchronized user activity tracker for mail actions.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),

          // Integration Metrics
          if (width >= 600)
            Row(
              children: [
                Expanded(child: _buildMetricCard(context, 'Sync Status', 'ONLINE', Icons.cloud_done_rounded, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard(context, 'Total Mail Sessions', '48 logs', Icons.history_rounded, Colors.blue)),
              ],
            )
          else
            Column(
              children: [
                _buildMetricCard(context, 'Sync Status', 'ONLINE', Icons.cloud_done_rounded, Colors.green),
                const SizedBox(height: 16),
                _buildMetricCard(context, 'Total Mail Sessions', '48 logs', Icons.history_rounded, Colors.blue),
              ],
            ),

          const SizedBox(height: 24),

          const Text(
            'Recent BNX Mail Activities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Render Mail specific activity logs
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              final mailActivities = sessionProvider.activities
                  .where((act) => act.module == 'BNX Mail' || act.category == 'Mail')
                  .toList();

              if (mailActivities.isEmpty) {
                return const NeumorphicCard(
                  borderRadius: 16,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No recent mail app sessions logged.'),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mailActivities.length,
                itemBuilder: (context, i) {
                  final act = mailActivities[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NeumorphicCard(
                      padding: const EdgeInsets.all(16),
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
                            child: Icon(Icons.mail_outline_rounded, color: Theme.of(context).primaryColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        act.description,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${act.timestamp.hour}:${act.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        act.device,
                                        style: TextStyle(fontSize: 9, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Status: ${act.status}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: act.status == 'Success' ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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

  Widget _buildMetricCard(BuildContext context, String title, String val, IconData icon, Color color) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                val,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
