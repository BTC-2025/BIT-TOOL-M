import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/calculator_provider.dart';
import '../models/cross_app_history_models.dart';

class CrossAppHistoryWidget extends StatefulWidget {
  final Function(CrossAppTape tape)? onLoadTape;

  const CrossAppHistoryWidget({super.key, this.onLoadTape});

  @override
  State<CrossAppHistoryWidget> createState() => _CrossAppHistoryWidgetState();
}

class _CrossAppHistoryWidgetState extends State<CrossAppHistoryWidget> {
  String? _selectedAppId;
  String? _selectedTapeId;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CalculatorProvider>(context, listen: false);
      if (provider.status == CalculatorStatus.initial) {
        provider.fetchHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<CalculatorProvider>();

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
      padding: const EdgeInsets.all(18),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildCurrentView(provider, isDark),
      ),
    );
  }

  Widget _buildCurrentView(CalculatorProvider provider, bool isDark) {
    final apps = provider.crossAppItems;
    final selectedApp = _selectedAppId != null
        ? apps.firstWhere(
            (a) => a.id == _selectedAppId,
            orElse: () => apps.first,
          )
        : null;

    final selectedTape = (selectedApp != null && _selectedTapeId != null)
        ? selectedApp.tapes.firstWhere(
            (t) => t.id == _selectedTapeId,
            orElse: () => selectedApp.tapes.isNotEmpty
                ? selectedApp.tapes.first
                : const CrossAppTape(
                    id: '',
                    title: '',
                    dateString: '',
                    itemCount: 0,
                    totalFormatted: '₹0.00',
                    totalValue: 0.0,
                    steps: [],
                  ),
          )
        : null;

    if (_selectedTapeId != null && selectedApp != null && selectedTape != null) {
      return _buildTapeDetailsView(provider, selectedApp, selectedTape, isDark);
    } else if (selectedApp != null) {
      return _buildAppTapesView(provider, selectedApp, isDark);
    } else {
      return _buildAppsListView(provider, apps, isDark);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LEVEL 1: APPLICATIONS LIST (Screenshot 1)
  // ═══════════════════════════════════════════════════════════
  Widget _buildAppsListView(
    CalculatorProvider provider,
    List<CrossAppItem> apps,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('AppsList'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                    : const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cross-App History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              tooltip: 'Refresh History',
              onPressed: () => provider.fetchHistory(forceRefresh: true),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Loading or Error State
        if (provider.isLoadingHistory && provider.sessions.isEmpty)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else if (provider.hasHistoryError && provider.sessions.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage ?? 'Failed to load history',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF4444),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.fetchHistory(forceRefresh: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          // Section Title: APPLICATIONS
          Text(
            'APPLICATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),

          // App Items
          Expanded(
            child: ListView.separated(
              itemCount: apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final app = apps[i];
                return _buildAppItemCard(app, isDark);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAppItemCard(CrossAppItem app, bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAppId = app.id;
          _selectedTapeId = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            _buildAppIcon(app.iconKey, isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${app.tapes.length} ${app.tapes.length == 1 ? "Tape" : "Tapes"} saved',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LEVEL 2: APP TAPES LIST (Screenshot 2 & 4)
  // ═══════════════════════════════════════════════════════════
  Widget _buildAppTapesView(
    CalculatorProvider provider,
    CrossAppItem app,
    bool isDark,
  ) {
    return Column(
      key: ValueKey('AppTapes_${app.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Header
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedAppId = null;
                  _selectedTapeId = null;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                app.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              tooltip: 'Refresh',
              onPressed: () => provider.fetchHistory(forceRefresh: true),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Subheader: APP ICON + <APP NAME> TAPES
        Row(
          children: [
            _buildAppIcon(app.iconKey, isDark, size: 16),
            const SizedBox(width: 6),
            Text(
              '${app.name.toUpperCase()} TAPES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Tapes or Empty State
        if (app.tapes.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 40,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No saved tapes for ${app.name}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saved tapes will automatically appear here.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: app.tapes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final tape = app.tapes[i];
                return _buildTapeItemCard(provider, tape, isDark);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTapeItemCard(
    CalculatorProvider provider,
    CrossAppTape tape,
    bool isDark,
  ) {
    return InkWell(
      onTap: () async {
        setState(() {
          _selectedTapeId = tape.id;
        });

        // If items are not loaded, fetch live session details from API
        if (tape.steps.isEmpty) {
          setState(() => _isLoadingDetails = true);
          try {
            await provider.fetchSessionDetails(tape.id);
          } finally {
            if (mounted) {
              setState(() => _isLoadingDetails = false);
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tape.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${tape.dateString} • ${tape.itemCount} ${tape.itemCount == 1 ? "item" : "items"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tape.totalFormatted,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              tooltip: 'Delete Tape',
              onPressed: () => _showDeleteConfirmation(provider, tape.id),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LEVEL 3: TAPE DETAILS (Screenshot 3)
  // ═══════════════════════════════════════════════════════════
  Widget _buildTapeDetailsView(
    CalculatorProvider provider,
    CrossAppItem app,
    CrossAppTape tape,
    bool isDark,
  ) {
    return Column(
      key: ValueKey('TapeDetails_${tape.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Header
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedTapeId = null;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tape Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Color(0xFFEF4444),
              ),
              tooltip: 'Delete Session',
              onPressed: () => _showDeleteConfirmation(provider, tape.id),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Subheader: APP ICON + TAPE TITLE
        Row(
          children: [
            _buildAppIcon(app.iconKey, isDark, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tape.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tape Steps List or Loading
        if (_isLoadingDetails)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else if (tape.steps.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No recorded operations for this tape.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: tape.steps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final step = tape.steps[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            step.timestamp,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            step.expression,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            step.result,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Action: Load into Calculator
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.onLoadTape != null) {
                widget.onLoadTape!(tape);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Loaded "${tape.title}" to Beta Calc'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.calculate_rounded, size: 18),
            label: const Text(
              'Load to Calculator',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(CalculatorProvider provider, String sessionId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Tape Session'),
          content: const Text(
            'Are you sure you want to permanently delete this tape session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await provider.deleteSession(sessionId);
                  if (mounted && _selectedTapeId == sessionId) {
                    setState(() => _selectedTapeId = null);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tape session deleted successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete session: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ICON HELPER
  // ═══════════════════════════════════════════════════════════
  Widget _buildAppIcon(String iconKey, bool isDark, {double size = 28}) {
    switch (iconKey) {
      case 'bnx_mail':
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Image.asset(
            'assets/bnx_mail_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.mark_email_read_rounded,
              color: const Color(0xFF2563EB),
              size: size * 0.65,
            ),
          ),
        );
      case 'bit_tool':
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Image.asset(
            'assets/bit_tool_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.token_rounded,
              color: const Color(0xFF2563EB),
              size: size * 0.65,
            ),
          ),
        );
      case 'cliks':
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Image.asset(
            'assets/cliks_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.ads_click_rounded,
              color: const Color(0xFF2563EB),
              size: size * 0.65,
            ),
          ),
        );
      case 'cliks_business':
        return Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Image.asset(
            'assets/cliks_business_img.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.business_center_rounded,
              color: const Color(0xFF2563EB),
              size: size * 0.65,
            ),
          ),
        );
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(
            Icons.apps_rounded,
            color: const Color(0xFF2563EB),
            size: size * 0.65,
          ),
        );
    }
  }
}
