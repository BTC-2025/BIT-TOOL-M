import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'B2Auth Portal Security',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Security Risk Score Card
          NeumorphicCard(
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Risk Assessment Indicator',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${authProvider.riskScore}/100',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Profile Status: LOW RISK',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'No suspicious active tokens',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Triggers
          const Text(
            'Trigger Auth Simulations',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: NeumorphicButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    authProvider.triggerBiometricAuth();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Simulated Biometrics Request dispatched!',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Biometric Verify',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeumorphicButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () {
                    authProvider.triggerOTPRequest();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulated OTP SMS Dispatch triggered!'),
                      ),
                    );
                  },
                  child: const Text(
                    'Request OTP',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Events
          const Text(
            'Recent Auth Activity Log',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          NeumorphicCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildLogTile(
                  'Password Changed Successfully',
                  '12m ago',
                  Icons.key,
                  Colors.green,
                ),
                const Divider(height: 1),
                _buildLogTile(
                  'New Token Refresh Token Exchange',
                  '1h ago',
                  Icons.refresh,
                  Colors.blue,
                ),
                const Divider(height: 1),
                _buildLogTile(
                  'Device Registered: Chrome Windows',
                  '4h ago',
                  Icons.check_circle_outline,
                  Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(String desc, String time, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        desc,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
    );
  }
}
