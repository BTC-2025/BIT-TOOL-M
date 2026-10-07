import 'package:flutter/material.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;
  final Function(int) onNavigate;

  const SettingsScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
    required this.onNavigate,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Profile state
  String _profileName = 'Ravi Kumar C';
  String _profileEmail = 'ravikumar123@bnxmail.com';
  String _profilePhone = '+1 (555) 019-2834';
  String _profileCompany = 'BNX Inc.';

  // Settings preferences state
  bool _enableNotifications = true;
  bool _enableCloudBackup = false;
  String _syncInterval = '15 minutes';

  // Accounts list for switcher
  final List<Map<String, String>> _availableAccounts = [
    {
      'name': 'Ravi Kumar C',
      'email': 'ravikumar123@bnxmail.com',
      'avatar': 'R',
    },
    {
      'name': 'BNX Administrator',
      'email': 'admin@bnxecosystem.org',
      'avatar': 'A',
    },
    {'name': 'Developer Account', 'email': 'dev@bnxmail.com', 'avatar': 'D'},
  ];

  void _showAccountSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Switch Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._availableAccounts.map((acc) {
                final isCurrent = acc['email'] == _profileEmail;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NeumorphicButton(
                    onPressed: () {
                      setState(() {
                        _profileName = acc['name']!;
                        _profileEmail = acc['email']!;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Switched to ${acc['name']}')),
                      );
                    },
                    color: isCurrent
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : null,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            acc['avatar']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acc['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                acc['email']!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showMyProfileDialog() {
    final nameController = TextEditingController(text: _profileName);
    final phoneController = TextEditingController(text: _profilePhone);
    final companyController = TextEditingController(text: _profileCompany);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text(
            'Update Profile Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Organization'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            NeumorphicButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onPressed: () {
                setState(() {
                  _profileName = nameController.text.trim();
                  _profilePhone = phoneController.text.trim();
                  _profileCompany = companyController.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile details updated successfully'),
                  ),
                );
              },
              color: Theme.of(context).primaryColor,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsPreferences() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: const Text(
                'Advanced Preferences',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text(
                      'System Notifications',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _enableNotifications,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _enableNotifications = val);
                        setState(() => _enableNotifications = val);
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Cloud Backup & Sync',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _enableCloudBackup,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _enableCloudBackup = val);
                        setState(() => _enableCloudBackup = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _syncInterval,
                    decoration: const InputDecoration(
                      labelText: 'Data Sync Interval',
                    ),
                    items: ['5 minutes', '15 minutes', '1 hour', 'Daily'].map((
                      interval,
                    ) {
                      return DropdownMenuItem(
                        value: interval,
                        child: Text(interval),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _syncInterval = val);
                        setState(() => _syncInterval = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                NeumorphicButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onPressed: () => Navigator.pop(context),
                  color: Theme.of(context).primaryColor,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _triggerLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text(
            'Confirm Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to end this active dev session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            NeumorphicButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onPressed: () {
                Navigator.pop(context);
                widget.onNavigate(7); // Redirect back to AuthScreen index 7
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully logged out.')),
                );
              },
              color: Colors.red,
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarLetter = _profileName.isNotEmpty
        ? _profileName[0].toUpperCase()
        : 'R';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          // Large Avatar and Name Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    avatarLetter,
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _profileName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _profileEmail,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Accounts dropdown Switcher card
          GestureDetector(
            onTap: _showAccountSwitcher,
            child: NeumorphicCard(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.15),
                    child: Text(
                      avatarLetter,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _profileEmail,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick statistics to fill the gaps
          const Text(
            'Session Analytics',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: NeumorphicCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 14,
                  child: Column(
                    children: [
                      Text(
                        '12',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total Tools',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: NeumorphicCard(
                  padding: EdgeInsets.all(12),
                  borderRadius: 14,
                  child: Column(
                    children: [
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sync Status',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions / Menu Items
          const Text(
            'Settings & Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),

          _buildMenuItem(
            context,
            Icons.person_add_alt_1_outlined,
            'Manage Account',
            description: 'Restricted account configurations',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account management is currently restricted'),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _buildMenuItem(
            context,
            Icons.badge_outlined,
            'My Profile',
            description: 'Edit name, phone and organization',
            onTap: _showMyProfileDialog,
          ),
          const SizedBox(height: 14),
          _buildMenuItem(
            context,
            Icons.settings_outlined,
            'Settings',
            description: 'Manage backup, notifications & interval',
            onTap: _showSettingsPreferences,
          ),
          const SizedBox(height: 14),

          // Dark Mode Switch Card
          NeumorphicCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.nightlight_outlined,
                    color: Colors.blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Toggle client visuals',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isDark,
                  onChanged: widget.onThemeChanged,
                  activeThumbColor: Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button
          _buildLogoutButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    required String description,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: _triggerLogout,
      child: NeumorphicCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.red,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'End the current dev session',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.red, size: 18),
          ],
        ),
      ),
    );
  }
}
