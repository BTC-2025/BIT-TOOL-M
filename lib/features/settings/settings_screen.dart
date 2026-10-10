import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _fallbackDarkMode = false;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    // Gracefully listen to ThemeProvider if mounted in the Provider tree
    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider?>(context, listen: true);
    } catch (_) {
      themeProvider = null;
    }

    final bool isDark =
        themeProvider?.isDarkMode ??
        (Theme.of(context).brightness == Brightness.dark || _fallbackDarkMode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Title & Subtitle ───────────────────────────────────
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your preferences and account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // ── Top Cards: Profile & Appearance ──────────────────────────
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildProfileCard(isDark)),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 5,
                      child: _buildAppearanceCard(isDark, themeProvider),
                    ),
                  ],
                )
              else ...[
                _buildProfileCard(isDark),
                const SizedBox(height: 20),
                _buildAppearanceCard(isDark, themeProvider),
              ],

              const SizedBox(height: 20),

              // ── Bottom Card: About Bit Tool ──────────────────────────────
              _buildAboutCard(isDark),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _formatStorageString(UserModel? user) {
    if (user == null) return '0.00 GB / 15.00 GB';
    final num usedBytes = user.storageUsed ?? 0;
    final num limitBytes = (user.storageLimit != null && user.storageLimit! > 0)
        ? user.storageLimit!
        : (15 * 1024 * 1024 * 1024);
    final double usedGb = usedBytes / (1024 * 1024 * 1024);
    final double limitGb = limitBytes / (1024 * 1024 * 1024);
    return '${usedGb.toStringAsFixed(2)} GB / ${limitGb.toStringAsFixed(2)} GB';
  }

  double _getStorageProgress(UserModel? user) {
    if (user == null) return 0.0;
    final num usedBytes = user.storageUsed ?? 0;
    final num limitBytes = (user.storageLimit != null && user.storageLimit! > 0)
        ? user.storageLimit!
        : (15 * 1024 * 1024 * 1024);
    if (limitBytes <= 0) return 0.0;
    return (usedBytes / limitBytes).clamp(0.0, 1.0).toDouble();
  }

  // ── Profile Card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard(bool isDark) {
    AuthProvider? authProvider;
    try {
      authProvider = Provider.of<AuthProvider?>(context, listen: true);
    } catch (_) {
      authProvider = null;
    }

    final user = authProvider?.user;
    final isLoading = authProvider?.isLoading ?? false;
    final hasError = authProvider?.hasError ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              // App / Profile Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: isDark
                      ? Border.all(color: const Color(0xFF334155))
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/bit_tool_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.apps_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (user != null && user.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null
                          ? 'Active account and personal credentials'
                          : 'Your personal information',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (user != null)
                IconButton(
                  tooltip: 'Refresh Profile',
                  onPressed: (_isRefreshing || isLoading)
                      ? null
                      : () async {
                          setState(() => _isRefreshing = true);
                          try {
                            await authProvider?.fetchCurrentUser(isRetry: true);
                          } finally {
                            if (mounted) setState(() => _isRefreshing = false);
                          }
                        },
                  icon: (_isRefreshing || isLoading)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // User Identity Card / Guest Banner
          if (user != null)
            _buildAuthenticatedIdentity(isDark, user, authProvider)
          else
            _buildGuestIdentity(isDark, isLoading, hasError, authProvider),
          const SizedBox(height: 14),

          // Dynamic Info Tiles Grid
          _buildInfoGrid(isDark, user),

          const SizedBox(height: 16),

          // Storage Bar Section
          _buildStorageSection(isDark, user),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedIdentity(
    bool isDark,
    UserModel user,
    AuthProvider? authProvider,
  ) {
    final displayName = user.displayName;
    final email = user.email;
    final orgName = user.organization?.name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          // Dynamic Profile Picture with UserAvatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF2563EB),
                width: 2,
              ),
            ),
            child: UserAvatar(
              user: user,
              radius: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Name, Verification, and Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    if (orgName != null && orgName.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF2563EB))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (isDark
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF2563EB))
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          orgName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Account Options Dropdown
          PopupMenuButton<String>(
            tooltip: 'Account Options',
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            onSelected: (value) {
              if (value == 'switch') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              } else if (value == 'sign_out') {
                _confirmSignOut(authProvider);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'switch',
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Switch Account',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sign_out',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestIdentity(
    bool isDark,
    bool isLoading,
    bool hasError,
    AuthProvider? authProvider,
  ) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 14),
            Text(
              'Connecting to B2Auth...',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 22,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasError
                      ? 'Session expired or offline'
                      : 'Sign in to sync your tools & preferences',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text(
              'Sign In',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(bool isDark, UserModel? user) {
    String accountType = user?.accountType?.trim() ?? '';
    if (accountType.isEmpty) {
      accountType = user != null ? 'STANDARD' : 'GUEST';
    } else {
      accountType = accountType.toUpperCase();
    }

    final phoneNumber = (user?.phoneNumber?.trim().isNotEmpty ?? false)
        ? user!.phoneNumber!.trim()
        : 'Not set';

    final recoveryEmail = (user?.recoveryEmail?.trim().isNotEmpty ?? false)
        ? user!.recoveryEmail!.trim()
        : 'Not set';

    final dob =
        (user?.dob?.trim().isNotEmpty ?? false) ? user!.dob!.trim() : 'Not set';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                isDark: isDark,
                icon: Icons.work_outline_rounded,
                label: 'ACCOUNT TYPE',
                value: accountType,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                isDark: isDark,
                icon: Icons.phone_outlined,
                label: 'PHONE NUMBER',
                value: phoneNumber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                isDark: isDark,
                icon: Icons.mail_outline_rounded,
                label: 'RECOVERY EMAIL',
                value: recoveryEmail,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInfoTile(
                isDark: isDark,
                icon: Icons.calendar_today_outlined,
                label: 'DATE OF BIRTH',
                value: dob,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageSection(bool isDark, UserModel? user) {
    final storageString = _formatStorageString(user);
    final progress = _getStorageProgress(user);
    final percent = (progress * 100).round();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dns_outlined,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Storage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    storageString,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF2563EB))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? const Color(0xFFEF4444) : const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(AuthProvider? authProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of this account on Bit Tool?',
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await authProvider?.signOut();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Successfully signed out'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Appearance Card ───────────────────────────────────────────────────────
  Widget _buildAppearanceCard(bool isDark, ThemeProvider? themeProvider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF581C87).withValues(alpha: 0.5)
                      : const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: isDark
                      ? const Color(0xFFC084FC)
                      : const Color(0xFF9333EA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customize your workspace',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Option: Light Mode
          _buildThemeOption(
            isDarkScreen: isDark,
            title: 'Light Mode',
            icon: Icons.wb_sunny_outlined,
            isSelected: !isDark,
            onTap: () {
              if (themeProvider != null) {
                themeProvider.setDarkMode(false);
              } else {
                setState(() => _fallbackDarkMode = false);
              }
            },
          ),
          const SizedBox(height: 12),

          // Option: Dark Mode
          _buildThemeOption(
            isDarkScreen: isDark,
            title: 'Dark Mode',
            icon: Icons.nightlight_outlined,
            isSelected: isDark,
            onTap: () {
              if (themeProvider != null) {
                themeProvider.setDarkMode(true);
              } else {
                setState(() => _fallbackDarkMode = true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required bool isDarkScreen,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color getTileBg() {
      if (isSelected) {
        return isDarkScreen
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
            : const Color(0xFFF0F7FF);
      }
      return isDarkScreen ? const Color(0xFF0F172A) : Colors.white;
    }

    Color getBorderColor() {
      if (isSelected) {
        return isDarkScreen ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
      }
      return isDarkScreen ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    }

    Color getTextColor() {
      if (isSelected) {
        return isDarkScreen ? Colors.white : const Color(0xFF0F172A);
      }
      return isDarkScreen ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    }

    Color getIconColor() {
      if (isSelected) {
        return isDarkScreen ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      }
      return isDarkScreen ? const Color(0xFF64748B) : const Color(0xFF64748B);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: getTileBg(),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: getBorderColor(),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: getIconColor()),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: getTextColor(),
              ),
            ),
            const Spacer(),
            // Radio Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDarkScreen
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF2563EB))
                      : (isDarkScreen
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1)),
                  width: isSelected ? 5.5 : 1.5,
                ),
                color: isSelected
                    ? (isDarkScreen ? const Color(0xFF1E293B) : Colors.white)
                    : (isDarkScreen ? const Color(0xFF0F172A) : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── About Bit Tool Card ───────────────────────────────────────────────────
  Widget _buildAboutCard(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.6)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF16A34A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Bit Tool',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Bit Tool is a premium suite of productivity applications designed to help you work smarter and faster. '
            'Built with modern web technologies, it offers a seamless and elegant experience across all your devices.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
