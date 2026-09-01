import 'package:flutter/material.dart';
import '../../core/widgets/neumorphic_widgets.dart';
import '../../core/theme/app_spacing.dart';

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final TextEditingController _testController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastKey = 'None';
  int _charCount = 0;

  @override
  void dispose() {
    _testController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Keyboard Diagnostics',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Test your keys and view shortcuts below.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Test Input area
          NeumorphicCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INTERACTIVE KEYBOARD TESTER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                RawKeyboardListener(
                  focusNode: _focusNode,
                  onKey: (event) {
                    setState(() {
                      _lastKey = event.logicalKey.keyLabel;
                    });
                  },
                  child: NeumorphicTextField(
                    controller: _testController,
                    hintText: 'Type here to test key responses...',
                    prefixIcon: Icons.keyboard_alt_outlined,
                    onChanged: (val) {
                      setState(() {
                        _charCount = val.length;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricCard(context, 'Last Key Detected', _lastKey, Icons.fingerprint),
                    const SizedBox(width: 12),
                    _buildMetricCard(context, 'Character Count', _charCount.toString(), Icons.abc),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Shortcut cheat sheet
          Text(
            'System Shortcuts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              _buildShortcutRow(context, 'Save Log', 'Ctrl + S', Icons.save_alt_rounded),
              const SizedBox(height: AppSpacing.elementSpacing),
              _buildShortcutRow(context, 'Search Workspace', 'Ctrl + F', Icons.search),
              const SizedBox(height: AppSpacing.elementSpacing),
              _buildShortcutRow(context, 'Notifications Panel', 'Ctrl + N', Icons.notifications_active_outlined),
              const SizedBox(height: AppSpacing.elementSpacing),
              _buildShortcutRow(context, 'Theme Switcher', 'Ctrl + T', Icons.dark_mode_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String val, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    val,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutRow(BuildContext context, String desc, String combo, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NeumorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF1E293B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Text(
              combo,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
