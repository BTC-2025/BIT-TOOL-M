import 'package:flutter/material.dart';
import '../models/session_activity.dart';

class SessionProvider extends ChangeNotifier {
  final List<SessionActivity> _activities = [];

  SessionProvider() {
    _seedInitialData();
  }

  List<SessionActivity> get activities => List.unmodifiable(_activities);

  void logActivity({
    required String iconName,
    required String device,
    required String module,
    required String duration,
    required String status,
    required String description,
    required String category,
  }) {
    final newActivity = SessionActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      iconName: iconName,
      timestamp: DateTime.now(),
      device: device,
      module: module,
      duration: duration,
      status: status,
      description: description,
      category: category,
    );
    _activities.insert(0, newActivity);
    notifyListeners();
  }

  void clearHistory() {
    _activities.clear();
    logActivity(
      iconName: 'delete',
      device: 'Desktop Browser',
      module: 'Session Tracking',
      duration: '0ms',
      status: 'Success',
      description: 'Activity timeline history cleared by administrator',
      category: 'System',
    );
    notifyListeners();
  }

  void _seedInitialData() {
    final now = DateTime.now();
    _activities.addAll([
      SessionActivity(
        id: '1',
        iconName: 'login',
        timestamp: now.subtract(const Duration(minutes: 5)),
        device: 'Windows Desktop',
        module: 'Authentication',
        duration: '120ms',
        status: 'Success',
        description: 'Login successful via B2Auth',
        category: 'Security',
      ),
      SessionActivity(
        id: '2',
        iconName: 'mail',
        timestamp: now.subtract(const Duration(minutes: 12)),
        device: 'iPhone 15',
        module: 'BNX Mail',
        duration: '450ms',
        status: 'Success',
        description: 'Opened Inbox and read mail from admin@b2auth.com',
        category: 'Mail',
      ),
      SessionActivity(
        id: '3',
        iconName: 'calculate',
        timestamp: now.subtract(const Duration(minutes: 25)),
        device: 'Web Browser',
        module: 'Calculator',
        duration: '1.2s',
        status: 'Success',
        description: 'Performed scientific calculation: sin(45) * 12',
        category: 'Utility',
      ),
      SessionActivity(
        id: 'c1',
        iconName: 'calculate',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 10)),
        device: 'Android App',
        module: 'Calculator',
        duration: '2.5s',
        status: 'Success',
        description: 'Invoice total calculated in clicksbusiness',
        category: 'Ecosystem',
      ),
      SessionActivity(
        id: 'c2',
        iconName: 'calculate',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 45)),
        device: 'Desktop Browser',
        module: 'Calculator',
        duration: '800ms',
        status: 'Success',
        description: 'Budget estimation performed for bnx mail campaign',
        category: 'Ecosystem',
      ),
      SessionActivity(
        id: 'c3',
        iconName: 'calculate',
        timestamp: now.subtract(const Duration(hours: 5, minutes: 20)),
        device: 'Server Side',
        module: 'Calculator',
        duration: '12ms',
        status: 'Success',
        description: 'Security entropy verified for B2Auth key generation',
        category: 'Ecosystem',
      ),
      SessionActivity(
        id: 'c4',
        iconName: 'calculate',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        device: 'clicks Mobile',
        module: 'Calculator',
        duration: '3.1s',
        status: 'Success',
        description: 'Discount rate applied in clicks mobile app',
        category: 'Ecosystem',
      ),
      SessionActivity(
        id: '4',
        iconName: 'contact_page',
        timestamp: now.subtract(const Duration(hours: 8)),
        device: 'iPad Pro',
        module: 'Contacts',
        duration: '800ms',
        status: 'Success',
        description: 'Added new contact "Sarah Connor" to Favorites',
        category: 'Contacts',
      ),
      SessionActivity(
        id: '5',
        iconName: 'security',
        timestamp: now.subtract(const Duration(hours: 12)),
        device: 'MacBook Pro',
        module: 'Authentication',
        duration: '3.1s',
        status: 'Failed',
        description:
            'OTP Verification timeout - suspicious login flag triggered',
        category: 'Security Alerts',
      ),
    ]);
  }
}
